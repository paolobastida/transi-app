package entradahttp

import (
	"bytes"
	"io"
	"log/slog"
	"net/http"
	"path/filepath"
	"strings"
	"time"

	"transi/internal/casosdeuso"
	"transi/internal/dominio"
	"transi/internal/puertos"
)

type respuestaAdjunto struct {
	ID      string `json:"id"`
	Tipo    string `json:"tipo"`
	Archivo string `json:"archivo"`
}

type respuestaCambio struct {
	ID          string             `json:"id"`
	Fecha       string             `json:"fecha"`
	Descripcion string             `json:"descripcion"`
	Adjuntos    []respuestaAdjunto `json:"adjuntos"`
}

type cuerpoEditarCambio struct {
	Fecha       string `json:"fecha"`
	Descripcion string `json:"descripcion"`
}

// manejarCrearCambio recibe multipart/form-data:
//   - campos de texto: "fecha" (AAAA-MM-DD) y "descripcion"
//   - archivos: "fotos" (fotos) y "audios" (notas de voz)
func (s *Servidor) manejarCrearCambio(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioActual(w, r)
	if !ok {
		return
	}
	if err := r.ParseMultipartForm(32 << 20); err != nil {
		escribirError(w, http.StatusBadRequest, "formulario_invalido", "se esperaba multipart/form-data")
		return
	}
	fecha, err := time.Parse(formatoFecha, r.FormValue("fecha"))
	if err != nil {
		escribirError(w, http.StatusBadRequest, "fecha_invalida", errFechaInvalida.Error())
		return
	}

	entrada := casosdeuso.EntradaCambio{
		Fecha:       fecha,
		Descripcion: r.FormValue("descripcion"),
	}
	var closers []io.Closer
	defer func() {
		for _, c := range closers {
			_ = c.Close()
		}
	}()
	entrada.Adjuntos = append(entrada.Adjuntos, leerArchivos(r, "fotos", dominio.TipoFoto, &closers)...)
	entrada.Adjuntos = append(entrada.Adjuntos, leerArchivos(r, "audios", dominio.TipoAudio, &closers)...)

	cambio, err := s.cambios.Registrar(r.Context(), actual.ID, entrada)
	if err != nil {
		s.manejarError(w, err)
		return
	}
	escribirJSON(w, http.StatusCreated, respuestaDeCambio(cambio))
}

func (s *Servidor) manejarListarCambios(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioActual(w, r)
	if !ok {
		return
	}
	filtro, ok := leerFiltroCambios(w, r)
	if !ok {
		return
	}
	cambios, err := s.cambios.Listar(r.Context(), actual.ID, filtro)
	if err != nil {
		s.manejarError(w, err)
		return
	}
	respuesta := make([]respuestaCambio, 0, len(cambios))
	for _, c := range cambios {
		respuesta = append(respuesta, respuestaDeCambio(c))
	}
	escribirJSON(w, http.StatusOK, respuesta)
}

func (s *Servidor) manejarEditarCambio(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioActual(w, r)
	if !ok {
		return
	}
	var cuerpo cuerpoEditarCambio
	if !decodificarJSON(w, r, &cuerpo) {
		return
	}
	fecha, err := time.Parse(formatoFecha, cuerpo.Fecha)
	if err != nil {
		escribirError(w, http.StatusBadRequest, "fecha_invalida", errFechaInvalida.Error())
		return
	}
	cambio, err := s.cambios.Editar(r.Context(), actual.ID, r.PathValue("id"), fecha, cuerpo.Descripcion)
	if err != nil {
		s.manejarError(w, err)
		return
	}
	escribirJSON(w, http.StatusOK, respuestaDeCambio(cambio))
}

func (s *Servidor) manejarDesactivarCambio(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioActual(w, r)
	if !ok {
		return
	}
	if err := s.cambios.Desactivar(r.Context(), actual.ID, r.PathValue("id")); err != nil {
		s.manejarError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// extensionPorTipo es la única extensión que se guarda para cada tipo de
// adjunto. No se conserva la que declara el cliente: así, un archivo con
// extensión ".html" o ".svg" no queda en disco como tal (si mañana se sirve
// algo desde acá, sería XSS almacenado).
var extensionPorTipo = map[dominio.TipoAdjunto]string{
	dominio.TipoFoto:  ".jpg",
	dominio.TipoAudio: ".m4a",
}

// leerArchivos toma los adjuntos del formulario, **verificando que el contenido
// coincida con el tipo declarado** en el campo. Confiar en el nombre del campo
// o en el Content-Type del cliente habría permitido guardar un .exe como "foto".
func leerArchivos(r *http.Request, campo string, tipo dominio.TipoAdjunto, closers *[]io.Closer) []casosdeuso.EntradaAdjunto {
	if r.MultipartForm == nil {
		return nil
	}
	var entradas []casosdeuso.EntradaAdjunto
	for _, cabecera := range r.MultipartForm.File[campo] {
		archivo, err := cabecera.Open()
		if err != nil {
			slog.Warn("no se pudo abrir un adjunto", "campo", campo, "error", err)
			continue
		}
		// Se leen los primeros bytes para decidir el tipo real. El archivo
		// queda posicionado donde estaba, así que sigue siendo legible.
		contenido, err := io.ReadAll(io.LimitReader(archivo, limiteArchivo))
		if err != nil {
			_ = archivo.Close()
			continue
		}
		if len(contenido) == 0 || !tipoCoincide(contenido, tipo) {
			slog.Warn("adjunto descartado: el contenido no coincide con el tipo declarado",
				"campo", campo, "detectado", http.DetectContentType(contenido))
			_ = archivo.Close()
			continue
		}
		*closers = append(*closers, io.NopCloser(bytes.NewReader(contenido)))
		entradas = append(entradas, casosdeuso.EntradaAdjunto{
			Tipo:      tipo,
			Nombre:    nombreSeguro(cabecera.Filename, extensionPorTipo[tipo]),
			Contenido: io.NopCloser(bytes.NewReader(contenido)),
		})
	}
	return entradas
}

// tipoCoincide contrasta los bytes iniciales con lo que se espera del tipo.
func tipoCoincide(contenido []byte, tipo dominio.TipoAdjunto) bool {
	detectado := http.DetectContentType(contenido)
	switch tipo {
	case dominio.TipoFoto:
		return strings.HasPrefix(detectado, "image/")
	case dominio.TipoAudio:
		// DetectContentType no siempre identifica audio (m4a/aac no tienen
		// firma conocida), así que también aceptamos los contenedores
		//compressed más comunes de audio.
		return strings.HasPrefix(detectado, "audio/") ||
			strings.Contains(detectado, "application/octet-stream")
	default:
		return false
	}
}

// nombreSeguro conserva el nombre que manda el cliente solo como etiqueta para
// mostrar, sin extensión y sin ruta.
func nombreSeguro(original, extension string) string {
	base := filepath.Base(filepath.FromSlash(original))
	base = strings.TrimSuffix(base, filepath.Ext(base))
	base = strings.Map(func(r rune) rune {
		if r < 32 || r == '/' || r == '\\' || r == 0 {
			return -1
		}
		return r
	}, base)
	if base == "" || base == "." {
		return "adjunto" + extension
	}
	if len(base) > 80 {
		base = base[:80]
	}
	return base + extension
}

func leerFiltroCambios(w http.ResponseWriter, r *http.Request) (puertos.FiltroCambios, bool) {
	desde, hasta, ok := leerRangoFechas(w, r)
	if !ok {
		return puertos.FiltroCambios{}, false
	}
	return puertos.FiltroCambios{Desde: desde, Hasta: hasta}, true
}

func respuestaDeCambio(c dominio.Cambio) respuestaCambio {
	adjuntos := make([]respuestaAdjunto, 0, len(c.Adjuntos))
	for _, a := range c.Adjuntos {
		adjuntos = append(adjuntos, respuestaAdjunto{ID: a.ID, Tipo: string(a.Tipo), Archivo: a.Archivo})
	}
	return respuestaCambio{
		ID:          c.ID,
		Fecha:       c.Fecha.Format(formatoFecha),
		Descripcion: c.Descripcion,
		Adjuntos:    adjuntos,
	}
}
