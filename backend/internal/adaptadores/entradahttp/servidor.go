// Package entradahttp es el adaptador de entrada HTTP: traduce JSON ↔ casos
// de uso. No contiene reglas de negocio.
package entradahttp

import (
	"context"
	"encoding/json"
	"net/http"
)

// verificarSalud es lo mínimo que el handler necesita de su caso de uso.
// Declararlo acá permite inyectar un falso en los tests.
type verificarSalud interface {
	Ejecutar(ctx context.Context) error
}

// Servidor arma las rutas de la API.
type Servidor struct {
	salud verificarSalud
	mux   *http.ServeMux
}

func NuevoServidor(salud verificarSalud) *Servidor {
	s := &Servidor{salud: salud, mux: http.NewServeMux()}
	s.mux.HandleFunc("GET /salud", s.manejarSalud)
	return s
}

// Handler expone el enrutador listo para http.Server.
func (s *Servidor) Handler() http.Handler { return s.mux }

func (s *Servidor) manejarSalud(w http.ResponseWriter, r *http.Request) {
	if err := s.salud.Ejecutar(r.Context()); err != nil {
		escribirJSON(w, http.StatusServiceUnavailable, map[string]string{"estado": "error"})
		return
	}
	escribirJSON(w, http.StatusOK, map[string]string{"estado": "ok"})
}

func escribirJSON(w http.ResponseWriter, codigo int, cuerpo any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(codigo)
	_ = json.NewEncoder(w).Encode(cuerpo)
}
