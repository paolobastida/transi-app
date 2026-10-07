// Package entradahttp es el adaptador de entrada HTTP: traduce JSON ↔ casos
// de uso. No contiene reglas de negocio.
package entradahttp

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"transi/internal/casosdeuso"
	"transi/internal/dominio"
	"transi/internal/puertos"
)

// Servidor arma las rutas de la API.
type Servidor struct {
	salud         casosdeuso.VerificarSalud
	identidad     casosdeuso.Identidad
	profesionales casosdeuso.Profesionales
	tratamientos  casosdeuso.Tratamientos
	tokens        puertos.Tokenizador
	mux           *http.ServeMux
}

func NuevoServidor(
	salud casosdeuso.VerificarSalud,
	identidad casosdeuso.Identidad,
	profesionales casosdeuso.Profesionales,
	tratamientos casosdeuso.Tratamientos,
	tokens puertos.Tokenizador,
) *Servidor {
	s := &Servidor{
		salud:         salud,
		identidad:     identidad,
		profesionales: profesionales,
		tratamientos:  tratamientos,
		tokens:        tokens,
		mux:           http.NewServeMux(),
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

	s.mux.HandleFunc("POST /profesionales", s.conAuth(s.manejarCrearProfesional))
	s.mux.HandleFunc("GET /profesionales", s.conAuth(s.manejarListarProfesionales))
	s.mux.HandleFunc("PUT /profesionales/{id}", s.conAuth(s.manejarEditarProfesional))
	s.mux.HandleFunc("DELETE /profesionales/{id}", s.conAuth(s.manejarDesactivarProfesional))

	s.mux.HandleFunc("POST /tratamientos", s.conAuth(s.manejarCrearTratamiento))
	s.mux.HandleFunc("GET /tratamientos", s.conAuth(s.manejarListarTratamientos))
	s.mux.HandleFunc("PUT /tratamientos/{id}", s.conAuth(s.manejarEditarTratamiento))
	s.mux.HandleFunc("DELETE /tratamientos/{id}", s.conAuth(s.manejarDesactivarTratamiento))
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

// manejarError traduce los errores del núcleo a códigos HTTP. Vive en un solo
// lugar para que todos los handlers respondan igual.
func (s *Servidor) manejarError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, dominio.ErrEmailInvalido):
		escribirError(w, http.StatusBadRequest, "email_invalido", err.Error())
	case errors.Is(err, dominio.ErrContrasenaCorta):
		escribirError(w, http.StatusBadRequest, "contrasena_corta", err.Error())
	case errors.Is(err, dominio.ErrProfesionalIncompleto):
		escribirError(w, http.StatusBadRequest, "profesional_incompleto", err.Error())
	case errors.Is(err, dominio.ErrTratamientoIncompleto):
		escribirError(w, http.StatusBadRequest, "tratamiento_incompleto", err.Error())
	case errors.Is(err, dominio.ErrFechasInvalidas):
		escribirError(w, http.StatusBadRequest, "fechas_invalidas", err.Error())
	case errors.Is(err, casosdeuso.ErrProfesionalInvalido):
		escribirError(w, http.StatusBadRequest, "profesional_invalido", err.Error())
	case errors.Is(err, puertos.ErrConflicto):
		escribirError(w, http.StatusConflict, "email_duplicado", "ese email ya está registrado")
	case errors.Is(err, casosdeuso.ErrCredencialesInvalidas):
		escribirError(w, http.StatusUnauthorized, "credenciales_invalidas", err.Error())
	case errors.Is(err, casosdeuso.ErrNoAutenticado):
		escribirError(w, http.StatusUnauthorized, "no_autenticado", err.Error())
	case errors.Is(err, puertos.ErrNoEncontrado):
		escribirError(w, http.StatusNotFound, "no_encontrado", "el recurso no existe")
	default:
		slog.Error("error interno", "error", err)
		escribirError(w, http.StatusInternalServerError, "error_interno", "ocurrió un error inesperado")
	}
}
