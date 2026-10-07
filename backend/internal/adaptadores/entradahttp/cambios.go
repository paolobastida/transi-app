package entradahttp

import (
	"encoding/json"
	"io"
	"net/http"
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
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
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
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
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
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
		return
	}
	var cuerpo cuerpoEditarCambio
	if err := json.NewDecoder(r.Body).Decode(&cuerpo); err != nil {
		escribirError(w, http.StatusBadRequest, "json_invalido", "el cuerpo no es JSON válido")
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
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
		return
	}
	if err := s.cambios.Desactivar(r.Context(), actual.ID, r.PathValue("id")); err != nil {
		s.manejarError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func leerArchivos(r *http.Request, campo string, tipo dominio.TipoAdjunto, closers *[]io.Closer) []casosdeuso.EntradaAdjunto {
	if r.MultipartForm == nil {
		return nil
	}
	var entradas []casosdeuso.EntradaAdjunto
	for _, cabecera := range r.MultipartForm.File[campo] {
		archivo, err := cabecera.Open()
		if err != nil {
			continue
		}
		*closers = append(*closers, archivo)
		entradas = append(entradas, casosdeuso.EntradaAdjunto{
			Tipo:      tipo,
			Nombre:    cabecera.Filename,
			Contenido: archivo,
		})
	}
	return entradas
}

func leerFiltroCambios(w http.ResponseWriter, r *http.Request) (puertos.FiltroCambios, bool) {
	consulta := r.URL.Query()
	var filtro puertos.FiltroCambios
	for _, campo := range []struct {
		nombre  string
		destino **time.Time
	}{{"desde", &filtro.Desde}, {"hasta", &filtro.Hasta}} {
		valor := consulta.Get(campo.nombre)
		if valor == "" {
			continue
		}
		fecha, err := time.Parse(formatoFecha, valor)
		if err != nil {
			escribirError(w, http.StatusBadRequest, "fecha_invalida", errFechaInvalida.Error())
			return puertos.FiltroCambios{}, false
		}
		*campo.destino = &fecha
	}
	return filtro, true
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
