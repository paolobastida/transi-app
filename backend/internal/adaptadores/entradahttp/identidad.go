package entradahttp

import (
	"errors"
	"log/slog"
	"net/http"
	"time"

	"transi/internal/casosdeuso"
	"transi/internal/puertos"
)

type cuerpoCredenciales struct {
	Email string `json:"email"`
	Clave string `json:"clave"`
}

type cuerpoRefresco struct {
	Refresco string `json:"refresco"`
}

func (s *Servidor) manejarRegistro(w http.ResponseWriter, r *http.Request) {
	var cuerpo cuerpoCredenciales
	if !decodificarJSON(w, r, &cuerpo) {
		return
	}
	u, err := s.identidad.Registrarse(r.Context(), casosdeuso.Credenciales{
		Email: cuerpo.Email,
		Clave: cuerpo.Clave,
	})
	if errors.Is(err, puertos.ErrConflicto) {
		// Mismo código y mismo cuerpo que un registro válido. Antes respondía
		// 409 "ese email ya está registrado", lo que permitía enumerar la base
		// de usuarios (relevante: saber quién usa esta app revela información
		// sensible). El cuerpo devuelto es idéntico en ambos casos, incluido
		// el id, para que un atacante no pueda deducir nada del contraste.
		slog.Warn("registro con email ya existente", "email", cuerpo.Email)
		escribirJSON(w, http.StatusCreated, map[string]string{"id": "", "email": cuerpo.Email})
		return
	}
	if err != nil {
		s.manejarError(w, err)
		return
	}
	escribirJSON(w, http.StatusCreated, map[string]string{"id": "", "email": u.Email})
}

func (s *Servidor) manejarLogin(w http.ResponseWriter, r *http.Request) {
	var cuerpo cuerpoCredenciales
	if !decodificarJSON(w, r, &cuerpo) {
		return
	}
	tokens, err := s.identidad.IniciarSesion(r.Context(), casosdeuso.Credenciales{
		Email: cuerpo.Email,
		Clave: cuerpo.Clave,
	})
	if err != nil {
		s.manejarError(w, err)
		return
	}
	escribirJSON(w, http.StatusOK, respuestaTokens(tokens))
}

func (s *Servidor) manejarRefresh(w http.ResponseWriter, r *http.Request) {
	var cuerpo cuerpoRefresco
	if !decodificarJSON(w, r, &cuerpo) {
		return
	}
	tokens, err := s.identidad.Renovar(r.Context(), cuerpo.Refresco)
	if err != nil {
		s.manejarError(w, err)
		return
	}
	escribirJSON(w, http.StatusOK, respuestaTokens(tokens))
}

func (s *Servidor) manejarLogout(w http.ResponseWriter, r *http.Request) {
	var cuerpo cuerpoRefresco
	if !decodificarJSON(w, r, &cuerpo) {
		return
	}
	if err := s.identidad.CerrarSesion(r.Context(), cuerpo.Refresco); err != nil {
		s.manejarError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *Servidor) manejarYo(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioActual(w, r)
	if !ok {
		return
	}
	u, err := s.identidad.QuienSoy(r.Context(), actual)
	if err != nil {
		s.manejarError(w, err)
		return
	}
	escribirJSON(w, http.StatusOK, map[string]string{"id": u.ID, "email": u.Email})
}

func respuestaTokens(t casosdeuso.Tokens) map[string]any {
	return map[string]any{
		"acceso":         t.Acceso,
		"refresco":       t.Refresco,
		"accesoExpiraEn": t.AccesoExpiraEn.Format(time.RFC3339),
	}
}
