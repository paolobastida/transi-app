package entradahttp

import (
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"transi/internal/casosdeuso"
	"transi/internal/dominio"
	"transi/internal/puertos"
)

const formatoFecha = "2006-01-02"

var errFechaInvalida = errors.New("fecha inválida; usá el formato AAAA-MM-DD")

type cuerpoTratamiento struct {
	Nombre        string  `json:"nombre"`
	Dosis         string  `json:"dosis"`
	Frecuencia    string  `json:"frecuencia"`
	FechaInicio   string  `json:"fechaInicio"`
	FechaFin      *string `json:"fechaFin"`
	ProfesionalID *string `json:"profesionalId"`
}

type respuestaTratamiento struct {
	ID            string  `json:"id"`
	Nombre        string  `json:"nombre"`
	Dosis         string  `json:"dosis"`
	Frecuencia    string  `json:"frecuencia"`
	FechaInicio   string  `json:"fechaInicio"`
	FechaFin      *string `json:"fechaFin"`
	ProfesionalID *string `json:"profesionalId"`
	Estado        string  `json:"estado"`
}

func (s *Servidor) manejarCrearTratamiento(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
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
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
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
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
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
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
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
	if err := json.NewDecoder(r.Body).Decode(&cuerpo); err != nil {
		escribirError(w, http.StatusBadRequest, "json_invalido", "el cuerpo no es JSON válido")
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
		Nombre:        cuerpo.Nombre,
		Dosis:         cuerpo.Dosis,
		Frecuencia:    cuerpo.Frecuencia,
		FechaInicio:   inicio,
		FechaFin:      fin,
		ProfesionalID: cuerpo.ProfesionalID,
	}, true
}

// leerFiltroTratamientos arma el filtro desde la query (?desde&hasta&estado).
func leerFiltroTratamientos(w http.ResponseWriter, r *http.Request) (puertos.FiltroTratamientos, bool) {
	consulta := r.URL.Query()
	filtro := puertos.FiltroTratamientos{Estado: consulta.Get("estado")}
	if filtro.Estado != "" && filtro.Estado != "activo" && filtro.Estado != "finalizado" {
		escribirError(w, http.StatusBadRequest, "estado_invalido", "estado debe ser 'activo' o 'finalizado'")
		return puertos.FiltroTratamientos{}, false
	}
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
			return puertos.FiltroTratamientos{}, false
		}
		*campo.destino = &fecha
	}
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
		ID:            t.ID,
		Nombre:        t.Nombre,
		Dosis:         t.Dosis,
		Frecuencia:    t.Frecuencia,
		FechaInicio:   t.FechaInicio.Format(formatoFecha),
		FechaFin:      fin,
		ProfesionalID: t.ProfesionalID,
		Estado:        estado,
	}
}
