package entradahttp

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"time"

	"transi/internal/casosdeuso"
	"transi/internal/dominio"
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
	if err := json.NewDecoder(r.Body).Decode(&cuerpo); err != nil {
		escribirError(w, http.StatusBadRequest, "json_invalido", "el cuerpo no es JSON válido")
		return
	}
	u, err := s.identidad.Registrarse(r.Context(), casosdeuso.Credenciales{
		Email: cuerpo.Email,
		Clave: cuerpo.Clave,
	})
	if err != nil {
		s.manejarErrorIdentidad(w, err)
		return
	}
	escribirJSON(w, http.StatusCreated, map[string]string{"id": u.ID, "email": u.Email})
}

func (s *Servidor) manejarLogin(w http.ResponseWriter, r *http.Request) {
	var cuerpo cuerpoCredenciales
	if err := json.NewDecoder(r.Body).Decode(&cuerpo); err != nil {
		escribirError(w, http.StatusBadRequest, "json_invalido", "el cuerpo no es JSON válido")
		return
	}
	tokens, err := s.identidad.IniciarSesion(r.Context(), casosdeuso.Credenciales{
		Email: cuerpo.Email,
		Clave: cuerpo.Clave,
	})
	if err != nil {
		s.manejarErrorIdentidad(w, err)
		return
	}
	escribirJSON(w, http.StatusOK, respuestaTokens(tokens))
}

func (s *Servidor) manejarRefresh(w http.ResponseWriter, r *http.Request) {
	var cuerpo cuerpoRefresco
	if err := json.NewDecoder(r.Body).Decode(&cuerpo); err != nil {
		escribirError(w, http.StatusBadRequest, "json_invalido", "el cuerpo no es JSON válido")
		return
	}
	tokens, err := s.identidad.Renovar(r.Context(), cuerpo.Refresco)
	if err != nil {
		s.manejarErrorIdentidad(w, err)
		return
	}
	escribirJSON(w, http.StatusOK, respuestaTokens(tokens))
}

func (s *Servidor) manejarLogout(w http.ResponseWriter, r *http.Request) {
	var cuerpo cuerpoRefresco
	if err := json.NewDecoder(r.Body).Decode(&cuerpo); err != nil {
		escribirError(w, http.StatusBadRequest, "json_invalido", "el cuerpo no es JSON válido")
		return
	}
	if err := s.identidad.CerrarSesion(r.Context(), cuerpo.Refresco); err != nil {
		s.manejarErrorIdentidad(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (s *Servidor) manejarYo(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
		return
	}
	u, err := s.identidad.QuienSoy(r.Context(), actual)
	if err != nil {
		s.manejarErrorIdentidad(w, err)
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

// manejarErrorIdentidad traduce los errores del núcleo a códigos HTTP.
func (s *Servidor) manejarErrorIdentidad(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, dominio.ErrEmailInvalido):
		escribirError(w, http.StatusBadRequest, "email_invalido", err.Error())
	case errors.Is(err, dominio.ErrContrasenaCorta):
		escribirError(w, http.StatusBadRequest, "contrasena_corta", err.Error())
	case errors.Is(err, puertos.ErrConflicto):
		escribirError(w, http.StatusConflict, "email_duplicado", "ese email ya está registrado")
	case errors.Is(err, casosdeuso.ErrCredencialesInvalidas):
		escribirError(w, http.StatusUnauthorized, "credenciales_invalidas", err.Error())
	case errors.Is(err, casosdeuso.ErrNoAutenticado):
		escribirError(w, http.StatusUnauthorized, "no_autenticado", err.Error())
	default:
		slog.Error("error interno en identidad", "error", err)
		escribirError(w, http.StatusInternalServerError, "error_interno", "ocurrió un error inesperado")
	}
}
