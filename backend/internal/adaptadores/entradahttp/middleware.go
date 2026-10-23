package entradahttp

import (
	"context"
	"encoding/json"
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

// usuarioActual recupera el usuario autenticado que dejó `conAuth`. Si no hay,
// escribe el 401 y devuelve ok=false. Así cada handler corta con un solo `if`
// en vez de repetir el mismo bloque de error.
func usuarioActual(w http.ResponseWriter, r *http.Request) (puertos.UsuarioAutenticado, bool) {
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
	}
	return actual, ok
}

// decodificarJSON lee el cuerpo JSON del request. Si viene mal formado, escribe
// el 400 y devuelve false: un solo lugar define qué es un "cuerpo inválido".
func decodificarJSON(w http.ResponseWriter, r *http.Request, destino any) bool {
	if err := json.NewDecoder(r.Body).Decode(destino); err != nil {
		escribirError(w, http.StatusBadRequest, "json_invalido", "el cuerpo no es JSON válido")
		return false
	}
	return true
}

// ConCORS permite que un navegador (por ejemplo la app Flutter en modo web)
// llame a la API desde otro origen. Los orígenes se configuran por variable de
// entorno; "*" permite todos (cómodo en desarrollo, a restringir en producción).
func ConCORS(origenes []string, siguiente http.Handler) http.Handler {
	permitidos := make(map[string]bool, len(origenes))
	for _, origen := range origenes {
		permitidos[origen] = true
	}
	permitirTodos := permitidos["*"]

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origen := r.Header.Get("Origin")
		if origen != "" && (permitirTodos || permitidos[origen]) {
			if permitirTodos {
				w.Header().Set("Access-Control-Allow-Origin", "*")
			} else {
				w.Header().Set("Access-Control-Allow-Origin", origen)
				w.Header().Set("Vary", "Origin")
			}
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
			w.Header().Set("Access-Control-Max-Age", "600")
		}
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		siguiente.ServeHTTP(w, r)
	})
}
