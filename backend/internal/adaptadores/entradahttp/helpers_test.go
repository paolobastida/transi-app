package entradahttp

import (
	"bytes"
	"context"
	"io"
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
	salud := casosdeuso.NuevoVerificarSalud(verificador)
	return NuevoServidor(salud, identidad, pruebas.TokenizadorFalso{})
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
