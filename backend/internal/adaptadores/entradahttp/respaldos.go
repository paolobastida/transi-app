package entradahttp

import (
	"bytes"
	"errors"
	"io"
	"net/http"
	"time"

	"transi/internal/dominio"
	"transi/internal/puertos"
)

const limiteRespaldo = 100 << 20 // 100 MB

type respuestaRespaldo struct {
	ID       string `json:"id"`
	CreadoEn string `json:"creadoEn"`
}

// manejarCrearRespaldo guarda una "foto" completa de los datos del usuario.
// El cuerpo es el snapshot (el servidor no lo interpreta).
func (s *Servidor) manejarCrearRespaldo(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
		return
	}
	datos, err := io.ReadAll(http.MaxBytesReader(w, r.Body, limiteRespaldo))
	if err != nil {
		escribirError(w, http.StatusBadRequest, "respaldo_invalido", "no se pudo leer el respaldo")
		return
	}
	if len(datos) == 0 {
		escribirError(w, http.StatusBadRequest, "respaldo_vacio", "el respaldo está vacío")
		return
	}
	respaldo, err := s.respaldos.Respaldar(r.Context(), actual.ID, bytes.NewReader(datos))
	if err != nil {
		s.manejarError(w, err)
		return
	}
	escribirJSON(w, http.StatusCreated, respuestaDeRespaldo(respaldo))
}

// manejarRestaurarRespaldo devuelve el contenido del último respaldo tal cual.
func (s *Servidor) manejarRestaurarRespaldo(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
		return
	}
	lector, respaldo, err := s.respaldos.Restaurar(r.Context(), actual.ID)
	if errors.Is(err, puertos.ErrNoEncontrado) {
		escribirError(w, http.StatusNotFound, "sin_respaldos", "no hay respaldos para restaurar")
		return
	}
	if err != nil {
		s.manejarError(w, err)
		return
	}
	defer lector.Close()

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("X-Respaldo-Id", respaldo.ID)
	w.Header().Set("X-Respaldo-Creado-En", respaldo.CreadoEn.UTC().Format(time.RFC3339))
	w.WriteHeader(http.StatusOK)
	_, _ = io.Copy(w, lector)
}

func (s *Servidor) manejarListarRespaldos(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
		return
	}
	respaldos, err := s.respaldos.Historial(r.Context(), actual.ID)
	if err != nil {
		s.manejarError(w, err)
		return
	}
	respuesta := make([]respuestaRespaldo, 0, len(respaldos))
	for _, respaldo := range respaldos {
		respuesta = append(respuesta, respuestaDeRespaldo(respaldo))
	}
	escribirJSON(w, http.StatusOK, respuesta)
}

func respuestaDeRespaldo(r dominio.Respaldo) respuestaRespaldo {
	return respuestaRespaldo{ID: r.ID, CreadoEn: r.CreadoEn.UTC().Format(time.RFC3339)}
}
