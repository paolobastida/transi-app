package entradahttp

import (
	"errors"
	"net/http"
	"testing"
)

func TestSaludRespondeOK(t *testing.T) {
	rec := pedir(t, nuevoServidorDePrueba(verificadorFalso{}), http.MethodGet, "/salud", nil, "")
	if rec.Code != http.StatusOK {
		t.Fatalf("código = %d, esperaba 200", rec.Code)
	}
	if obtenido := rec.Body.String(); obtenido != "{\"estado\":\"ok\"}\n" {
		t.Fatalf("cuerpo = %q", obtenido)
	}
}

func TestSaludConBaseCaida(t *testing.T) {
	rec := pedir(t, nuevoServidorDePrueba(verificadorFalso{err: errors.New("caída")}), http.MethodGet, "/salud", nil, "")
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("código = %d, esperaba 503", rec.Code)
	}
}
