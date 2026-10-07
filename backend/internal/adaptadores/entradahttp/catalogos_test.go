package entradahttp

import (
	"net/http"
	"testing"
)

func TestFlujoTratamientos(t *testing.T) {
	s := nuevoServidorDePrueba(verificadorFalso{})
	token := obtenerToken(t, s)

	// Crear (201)
	rec := pedir(t, s, http.MethodPost, "/tratamientos",
		[]byte(`{"nombre":"Estradiol","dosis":"2 mg","frecuencia":"cada día","fechaInicio":"2026-01-10"}`), token)
	if rec.Code != http.StatusCreated {
		t.Fatalf("crear: código = %d, cuerpo = %s", rec.Code, rec.Body.String())
	}

	// Fecha de fin anterior al inicio (400)
	rec = pedir(t, s, http.MethodPost, "/tratamientos",
		[]byte(`{"nombre":"X","dosis":"1","frecuencia":"d","fechaInicio":"2026-03-01","fechaFin":"2026-02-01"}`), token)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("fechas inválidas: código = %d, esperaba 400", rec.Code)
	}

	// Listar (200)
	rec = pedir(t, s, http.MethodGet, "/tratamientos", nil, token)
	if rec.Code != http.StatusOK {
		t.Fatalf("listar: código = %d", rec.Code)
	}

	// Sin token (401)
	rec = pedir(t, s, http.MethodGet, "/tratamientos", nil, "")
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("sin token: código = %d, esperaba 401", rec.Code)
	}
}
