package entradahttp

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
)

type saludFalsa struct{ err error }

func (s saludFalsa) Ejecutar(context.Context) error { return s.err }

func TestSaludRespondeOK(t *testing.T) {
	rec := pedirSalud(t, saludFalsa{})
	if rec.Code != http.StatusOK {
		t.Fatalf("código = %d, esperaba 200", rec.Code)
	}
	if obtenido := rec.Body.String(); obtenido != "{\"estado\":\"ok\"}\n" {
		t.Fatalf("cuerpo = %q", obtenido)
	}
}

func TestSaludConBaseCaida(t *testing.T) {
	rec := pedirSalud(t, saludFalsa{err: errors.New("caída")})
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("código = %d, esperaba 503", rec.Code)
	}
}

func pedirSalud(t *testing.T, salud saludFalsa) *httptest.ResponseRecorder {
	t.Helper()
	srv := NuevoServidor(salud)
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/salud", nil)
	srv.Handler().ServeHTTP(rec, req)
	return rec
}
