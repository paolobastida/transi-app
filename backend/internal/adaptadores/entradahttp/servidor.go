// Package entradahttp es el adaptador de entrada HTTP: traduce JSON ↔ casos
// de uso. No contiene reglas de negocio.
package entradahttp

import (
	"encoding/json"
	"net/http"

	"transi/internal/casosdeuso"
	"transi/internal/puertos"
)

// Servidor arma las rutas de la API.
type Servidor struct {
	salud     casosdeuso.VerificarSalud
	identidad casosdeuso.Identidad
	tokens    puertos.Tokenizador
	mux       *http.ServeMux
}

func NuevoServidor(
	salud casosdeuso.VerificarSalud,
	identidad casosdeuso.Identidad,
	tokens puertos.Tokenizador,
) *Servidor {
	s := &Servidor{
		salud:     salud,
		identidad: identidad,
		tokens:    tokens,
		mux:       http.NewServeMux(),
	}
	s.rutas()
	return s
}

// Handler expone el enrutador listo para http.Server.
func (s *Servidor) Handler() http.Handler { return s.mux }

func (s *Servidor) rutas() {
	s.mux.HandleFunc("GET /salud", s.manejarSalud)
	s.mux.HandleFunc("POST /auth/registro", s.manejarRegistro)
	s.mux.HandleFunc("POST /auth/login", s.manejarLogin)
	s.mux.HandleFunc("POST /auth/refresh", s.manejarRefresh)
	s.mux.HandleFunc("POST /auth/logout", s.manejarLogout)
	s.mux.HandleFunc("GET /auth/yo", s.conAuth(s.manejarYo))
}

func (s *Servidor) manejarSalud(w http.ResponseWriter, r *http.Request) {
	if err := s.salud.Ejecutar(r.Context()); err != nil {
		escribirError(w, http.StatusServiceUnavailable, "base_caida", "la base de datos no responde")
		return
	}
	escribirJSON(w, http.StatusOK, map[string]string{"estado": "ok"})
}

func escribirJSON(w http.ResponseWriter, codigo int, cuerpo any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(codigo)
	_ = json.NewEncoder(w).Encode(cuerpo)
}

func escribirError(w http.ResponseWriter, codigo int, clave, mensaje string) {
	escribirJSON(w, codigo, map[string]any{
		"error": map[string]string{"codigo": clave, "mensaje": mensaje},
	})
}
