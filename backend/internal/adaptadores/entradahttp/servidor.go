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
	salud        casosdeuso.VerificarSalud
	identidad    casosdeuso.Identidad
	tratamientos casosdeuso.Tratamientos
	cambios      casosdeuso.Cambios
	respaldos    casosdeuso.Respaldos
	tokens       puertos.Tokenizador
	mux          *http.ServeMux
	limites      *Limitador
}

func NuevoServidor(
	salud casosdeuso.VerificarSalud,
	identidad casosdeuso.Identidad,
	tratamientos casosdeuso.Tratamientos,
	cambios casosdeuso.Cambios,
	respaldos casosdeuso.Respaldos,
	tokens puertos.Tokenizador,
	limites *Limitador,
) *Servidor {
	s := &Servidor{
		salud:        salud,
		identidad:    identidad,
		tratamientos: tratamientos,
		cambios:      cambios,
		respaldos:    respaldos,
		tokens:       tokens,
		mux:          http.NewServeMux(),
		limites:      limites,
	}
	s.rutas()
	return s
}

// Handler expone el enrutador listo para http.Server.
func (s *Servidor) Handler() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Encabezados de endurecimiento en todas las respuestas. Las de
		// /cambios, /tratamientos y /respaldos llevan datos de salud: no deben
		// quedar cacheadas ni reinterpretarse como otro tipo de contenido.
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Cache-Control", "no-store")
		w.Header().Set("Referrer-Policy", "no-referrer")
		s.mux.ServeHTTP(w, r)
	})
}

func (s *Servidor) rutas() {
	s.mux.HandleFunc("GET /salud", s.manejarSalud)

	// /auth/* lleva límite de intentos: sin esto cada login dispara un bcrypt
	// y alcanza tanto para fuerza bruta como para tumbar el servicio por CPU.
	s.mux.HandleFunc("POST /auth/registro",
		conLimiteIntentos(s.limites,
			conLimiteCuerpo(limiteCuerpoJSON, s.manejarRegistro)))
	s.mux.HandleFunc("POST /auth/login",
		conLimiteIntentos(s.limites,
			conLimiteCuerpo(limiteCuerpoJSON, s.manejarLogin)))
	s.mux.HandleFunc("POST /auth/refresh",
		conLimiteIntentos(s.limites,
			conLimiteCuerpo(limiteCuerpoJSON, s.manejarRefresh)))
	s.mux.HandleFunc("POST /auth/logout",
		conLimiteCuerpo(limiteCuerpoJSON, s.manejarLogout))
	s.mux.HandleFunc("GET /auth/yo", s.conAuth(s.manejarYo))

	s.mux.HandleFunc("POST /tratamientos",
		s.conAuth(conLimiteCuerpo(limiteCuerpoJSON, s.manejarCrearTratamiento)))
	s.mux.HandleFunc("GET /tratamientos", s.conAuth(s.manejarListarTratamientos))
	s.mux.HandleFunc("PUT /tratamientos/{id}",
		s.conAuth(conLimiteCuerpo(limiteCuerpoJSON, s.manejarEditarTratamiento)))
	s.mux.HandleFunc("DELETE /tratamientos/{id}", s.conAuth(s.manejarDesactivarTratamiento))

	// multipart: el límite va en el body, antes de ParseMultipartForm.
	s.mux.HandleFunc("POST /cambios",
		s.conAuth(conLimiteCuerpo(limiteCuerpoMultipart, s.manejarCrearCambio)))
	s.mux.HandleFunc("GET /cambios", s.conAuth(s.manejarListarCambios))
	s.mux.HandleFunc("PUT /cambios/{id}",
		s.conAuth(conLimiteCuerpo(limiteCuerpoMultipart, s.manejarEditarCambio)))
	s.mux.HandleFunc("DELETE /cambios/{id}", s.conAuth(s.manejarDesactivarCambio))

	s.mux.HandleFunc("PUT /respaldos", s.conAuth(s.manejarCrearRespaldo))
	s.mux.HandleFunc("GET /respaldos", s.conAuth(s.manejarListarRespaldos))
	s.mux.HandleFunc("GET /respaldos/ultimo", s.conAuth(s.manejarRestaurarRespaldo))
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

// traduccionError describe a qué respuesta HTTP se traduce un error del núcleo.
type traduccionError struct {
	err     error
	estado  int
	codigo  string
	mensaje string // vacío = usar err.Error()
}

// traduccionesError es la tabla de traducción error → HTTP. Una tabla (en vez
// de un switch) mantiene la función **cerrada a modificación** y **abierta a
// extensión**: agregar un error nuevo es agregar una fila, sin tocar la lógica.
var traduccionesError = []traduccionError{
	{dominio.ErrEmailInvalido, http.StatusBadRequest, "email_invalido", ""},
	{dominio.ErrContrasenaCorta, http.StatusBadRequest, "contrasena_corta", ""},
	{dominio.ErrContrasenaLarga, http.StatusBadRequest, "contrasena_larga", ""},
	{dominio.ErrTratamientoIncompleto, http.StatusBadRequest, "tratamiento_incompleto", ""},
	{dominio.ErrFechasInvalidas, http.StatusBadRequest, "fechas_invalidas", ""},
	{dominio.ErrFechaFutura, http.StatusBadRequest, "fecha_futura", ""},
	{dominio.ErrCambioVacio, http.StatusBadRequest, "cambio_vacio", ""},
	{puertos.ErrConflicto, http.StatusConflict, "email_duplicado", "ese email ya está registrado"},
	{casosdeuso.ErrCredencialesInvalidas, http.StatusUnauthorized, "credenciales_invalidas", ""},
	{casosdeuso.ErrNoAutenticado, http.StatusUnauthorized, "no_autenticado", ""},
	{puertos.ErrNoEncontrado, http.StatusNotFound, "no_encontrado", "el recurso no existe"},
}

// manejarError traduce los errores del núcleo a códigos HTTP. Vive en un solo
// lugar para que todos los handlers respondan igual.
func (s *Servidor) manejarError(w http.ResponseWriter, err error) {
	for _, t := range traduccionesError {
		if errors.Is(err, t.err) {
			mensaje := t.mensaje
			if mensaje == "" {
				mensaje = err.Error()
			}
			escribirError(w, t.estado, t.codigo, mensaje)
			return
		}
	}
	slog.Error("error interno", "error", err)
	escribirError(w, http.StatusInternalServerError, "error_interno", "ocurrió un error inesperado")
}
