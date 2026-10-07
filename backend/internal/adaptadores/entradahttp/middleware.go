package entradahttp

import (
	"context"
	"net/http"
	"strings"

	"transi/internal/puertos"
)

type claveContexto struct{}

var claveUsuario = claveContexto{}

// conAuth exige un access token válido en `Authorization: Bearer <token>` y
// deja el usuario autenticado disponible en el contexto del request.
func (s *Servidor) conAuth(siguiente http.HandlerFunc) http.HandlerFunc {
	const prefijo = "Bearer "
	return func(w http.ResponseWriter, r *http.Request) {
		cabecera := r.Header.Get("Authorization")
		if !strings.HasPrefix(cabecera, prefijo) {
			escribirError(w, http.StatusUnauthorized, "no_autenticado", "falta el token de acceso")
			return
		}
		actual, err := s.tokens.ValidarAcceso(strings.TrimPrefix(cabecera, prefijo))
		if err != nil {
			escribirError(w, http.StatusUnauthorized, "token_invalido", "el token no es válido o venció")
			return
		}
		ctx := context.WithValue(r.Context(), claveUsuario, actual)
		siguiente(w, r.WithContext(ctx))
	}
}

func usuarioDesdeContexto(ctx context.Context) (puertos.UsuarioAutenticado, bool) {
	actual, ok := ctx.Value(claveUsuario).(puertos.UsuarioAutenticado)
	return actual, ok
}
