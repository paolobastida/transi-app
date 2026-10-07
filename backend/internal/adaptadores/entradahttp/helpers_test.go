package entradahttp

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"transi/internal/casosdeuso"
	"transi/internal/pruebas"
)

// verificadorFalso simula el chequeo de salud de la base.
type verificadorFalso struct{ err error }

func (v verificadorFalso) Ping(context.Context) error { return v.err }

// nuevoServidorDePrueba arma un Servidor con casos de uso reales sobre
// adaptadores falsos: probamos el handler sin red ni base de datos.
func nuevoServidorDePrueba(verificador verificadorFalso) *Servidor {
	identidad := casosdeuso.NuevaIdentidad(
		pruebas.NuevoUsuariosFalso(),
		pruebas.NuevoSesionesFalso(),
		pruebas.HasherFalso{},
		pruebas.TokenizadorFalso{},
		24*time.Hour,
	)
	profesionales := casosdeuso.NuevoProfesionales(pruebas.NuevoProfesionalesFalso())
	tratamientos := casosdeuso.NuevoTratamientos(pruebas.NuevoTratamientosFalso(), pruebas.NuevoProfesionalesFalso())
	salud := casosdeuso.NuevoVerificarSalud(verificador)
	return NuevoServidor(salud, identidad, profesionales, tratamientos, pruebas.TokenizadorFalso{})
}

func pedir(t *testing.T, s *Servidor, metodo, ruta string, cuerpo []byte, token string) *httptest.ResponseRecorder {
	t.Helper()
	var lector io.Reader
	if cuerpo != nil {
		lector = bytes.NewReader(cuerpo)
	}
	req := httptest.NewRequest(metodo, ruta, lector)
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	rec := httptest.NewRecorder()
	s.Handler().ServeHTTP(rec, req)
	return rec
}

// obtenerToken registra e inicia sesión, y devuelve el access token.
func obtenerToken(t *testing.T, s *Servidor) string {
	t.Helper()
	credenciales := []byte(`{"email":"tina@transi.test","clave":"secreto123"}`)
	if rec := pedir(t, s, http.MethodPost, "/auth/registro", credenciales, ""); rec.Code != http.StatusCreated {
		t.Fatalf("registro de prueba: %d", rec.Code)
	}
	rec := pedir(t, s, http.MethodPost, "/auth/login", credenciales, "")
	var respuesta struct {
		Acceso string `json:"acceso"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &respuesta); err != nil {
		t.Fatalf("login de prueba: %v", err)
	}
	return respuesta.Acceso
}
