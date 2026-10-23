package entradahttp

import (
	"errors"
	"net/http"
	"strings"
	"time"

	"transi/internal/casosdeuso"
	"transi/internal/dominio"
	"transi/internal/puertos"
)

const formatoFecha = "2006-01-02"

var errFechaInvalida = errors.New("fecha inválida; usá el formato AAAA-MM-DD")

type cuerpoTratamiento struct {
	Nombre                  string   `json:"nombre"`
	Dosis                   string   `json:"dosis"`
	Frecuencia              string   `json:"frecuencia"`
	FechaInicio             string   `json:"fechaInicio"`
	FechaFin                *string  `json:"fechaFin"`
	Via                     *string  `json:"via"`
	Presentacion            *string  `json:"presentacion"`
	DosisCantidad           *float64 `json:"dosisCantidad"`
	DosisUnidad             *string  `json:"dosisUnidad"`
	Indicacion              *string  `json:"indicacion"`
	ProfesionalNombre       *string  `json:"profesionalNombre"`
	ProfesionalEspecialidad *string  `json:"profesionalEspecialidad"`
}

type respuestaTratamiento struct {
	ID                      string   `json:"id"`
	Nombre                  string   `json:"nombre"`
	Dosis                   string   `json:"dosis"`
	Frecuencia              string   `json:"frecuencia"`
	FechaInicio             string   `json:"fechaInicio"`
	FechaFin                *string  `json:"fechaFin"`
	Estado                  string   `json:"estado"`
	Via                     *string  `json:"via"`
	Presentacion            *string  `json:"presentacion"`
	DosisCantidad           *float64 `json:"dosisCantidad"`
	DosisUnidad             *string  `json:"dosisUnidad"`
	Indicacion              *string  `json:"indicacion"`
	ProfesionalNombre       *string  `json:"profesionalNombre"`
	ProfesionalEspecialidad *string  `json:"profesionalEspecialidad"`
}

func (s *Servidor) manejarCrearTratamiento(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioActual(w, r)
	if !ok {
		return
	}
	entrada, ok := leerEntradaTratamiento(w, r)
	if !ok {
		return
	}
	t, err := s.tratamientos.Crear(r.Context(), actual.ID, entrada)
	if err != nil {
		s.manejarError(w, err)
		return
	}
	escribirJSON(w, http.StatusCreated, respuestaDeTratamiento(t))
}

func (s *Servidor) manejarListarTratamientos(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioActual(w, r)
	if !ok {
		return
	}
	filtro, ok := leerFiltroTratamientos(w, r)
	if !ok {
		return
	}
	tratamientos, err := s.tratamientos.Listar(r.Context(), actual.ID, filtro)
	if err != nil {
		s.manejarError(w, err)
		return
	}
	respuesta := make([]respuestaTratamiento, 0, len(tratamientos))
	for _, t := range tratamientos {
		respuesta = append(respuesta, respuestaDeTratamiento(t))
	}
	escribirJSON(w, http.StatusOK, respuesta)
}

func (s *Servidor) manejarEditarTratamiento(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioActual(w, r)
	if !ok {
		return
	}
	entrada, ok := leerEntradaTratamiento(w, r)
	if !ok {
		return
	}
	t, err := s.tratamientos.Editar(r.Context(), actual.ID, r.PathValue("id"), entrada)
	if err != nil {
		s.manejarError(w, err)
		return
	}
	escribirJSON(w, http.StatusOK, respuestaDeTratamiento(t))
}

func (s *Servidor) manejarDesactivarTratamiento(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioActual(w, r)
	if !ok {
		return
	}
	if err := s.tratamientos.Desactivar(r.Context(), actual.ID, r.PathValue("id")); err != nil {
		s.manejarError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// leerEntradaTratamiento decodifica el cuerpo y parsea las fechas.
func leerEntradaTratamiento(w http.ResponseWriter, r *http.Request) (casosdeuso.EntradaTratamiento, bool) {
	var cuerpo cuerpoTratamiento
	if !decodificarJSON(w, r, &cuerpo) {
		return casosdeuso.EntradaTratamiento{}, false
	}
	inicio, err := time.Parse(formatoFecha, cuerpo.FechaInicio)
	if err != nil {
		escribirError(w, http.StatusBadRequest, "fecha_invalida", errFechaInvalida.Error())
		return casosdeuso.EntradaTratamiento{}, false
	}
	var fin *time.Time
	if cuerpo.FechaFin != nil && *cuerpo.FechaFin != "" {
		fecha, err := time.Parse(formatoFecha, *cuerpo.FechaFin)
		if err != nil {
			escribirError(w, http.StatusBadRequest, "fecha_invalida", errFechaInvalida.Error())
			return casosdeuso.EntradaTratamiento{}, false
		}
		fin = &fecha
	}
	return casosdeuso.EntradaTratamiento{
		Nombre:                  cuerpo.Nombre,
		Dosis:                   cuerpo.Dosis,
		Frecuencia:              cuerpo.Frecuencia,
		FechaInicio:             inicio,
		FechaFin:                fin,
		Via:                     opcional(cuerpo.Via),
		Presentacion:            opcional(cuerpo.Presentacion),
		DosisCantidad:           cuerpo.DosisCantidad,
		DosisUnidad:             opcional(cuerpo.DosisUnidad),
		Indicacion:              opcional(cuerpo.Indicacion),
		ProfesionalNombre:       opcional(cuerpo.ProfesionalNombre),
		ProfesionalEspecialidad: opcional(cuerpo.ProfesionalEspecialidad),
	}, true
}

// opcional normaliza un texto opcional: vacío o en blanco se vuelve nil.
func opcional(s *string) *string {
	if s == nil {
		return nil
	}
	v := strings.TrimSpace(*s)
	if v == "" {
		return nil
	}
	return &v
}

// leerFiltroTratamientos arma el filtro desde la query (?desde&hasta&estado).
func leerFiltroTratamientos(w http.ResponseWriter, r *http.Request) (puertos.FiltroTratamientos, bool) {
	filtro := puertos.FiltroTratamientos{Estado: r.URL.Query().Get("estado")}
	if filtro.Estado != "" && filtro.Estado != "activo" && filtro.Estado != "finalizado" {
		escribirError(w, http.StatusBadRequest, "estado_invalido", "estado debe ser 'activo' o 'finalizado'")
		return puertos.FiltroTratamientos{}, false
	}
	desde, hasta, ok := leerRangoFechas(w, r)
	if !ok {
		return puertos.FiltroTratamientos{}, false
	}
	filtro.Desde = desde
	filtro.Hasta = hasta
	return filtro, true
}

func respuestaDeTratamiento(t dominio.Tratamiento) respuestaTratamiento {
	estado := "activo"
	if t.Finalizado() {
		estado = "finalizado"
	}
	var fin *string
	if t.FechaFin != nil {
		formateada := t.FechaFin.Format(formatoFecha)
		fin = &formateada
	}
	return respuestaTratamiento{
		ID:                      t.ID,
		Nombre:                  t.Nombre,
		Dosis:                   t.Dosis,
		Frecuencia:              t.Frecuencia,
		FechaInicio:             t.FechaInicio.Format(formatoFecha),
		FechaFin:                fin,
		Estado:                  estado,
		Via:                     t.Via,
		Presentacion:            t.Presentacion,
		DosisCantidad:           t.DosisCantidad,
		DosisUnidad:             t.DosisUnidad,
		Indicacion:              t.Indicacion,
		ProfesionalNombre:       t.ProfesionalNombre,
		ProfesionalEspecialidad: t.ProfesionalEspecialidad,
	}
}
