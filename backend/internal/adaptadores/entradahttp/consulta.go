package entradahttp

import (
	"net/http"
	"time"
)

// leerRangoFechas lee los parámetros opcionales ?desde y ?hasta (AAAA-MM-DD).
//
// Lo comparten tratamientos y cambios: el formato de fecha es uno solo. Antes
// cada filtro repetía el mismo bucle de parseo; si mañana cambia el formato,
// se toca acá y no en dos lugares. Si una fecha viene mal, escribe el 400 y
// devuelve ok=false.
func leerRangoFechas(w http.ResponseWriter, r *http.Request) (desde, hasta *time.Time, ok bool) {
	consulta := r.URL.Query()
	for _, campo := range []struct {
		nombre  string
		destino **time.Time
	}{{"desde", &desde}, {"hasta", &hasta}} {
		valor := consulta.Get(campo.nombre)
		if valor == "" {
			continue
		}
		fecha, err := time.Parse(formatoFecha, valor)
		if err != nil {
			escribirError(w, http.StatusBadRequest, "fecha_invalida", errFechaInvalida.Error())
			return nil, nil, false
		}
		*campo.destino = &fecha
	}
	return desde, hasta, true
}
