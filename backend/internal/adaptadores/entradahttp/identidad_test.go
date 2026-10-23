package entradahttp

import (
	"encoding/json"
	"net/http"
	"reflect"
	"testing"
)

func TestFlujoRegistroLoginYo(t *testing.T) {
	s := nuevoServidorDePrueba(verificadorFalso{})

	// Registro
	rec := pedir(t, s, http.MethodPost, "/auth/registro",
		[]byte(`{"email":"tina@transi.test","clave":"secreto123"}`), "")
	if rec.Code != http.StatusCreated {
		t.Fatalf("registro: código = %d, cuerpo = %s", rec.Code, rec.Body.String())
	}

	// Login
	rec = pedir(t, s, http.MethodPost, "/auth/login",
		[]byte(`{"email":"tina@transi.test","clave":"secreto123"}`), "")
	if rec.Code != http.StatusOK {
		t.Fatalf("login: código = %d, cuerpo = %s", rec.Code, rec.Body.String())
	}
	var tokens struct {
		Acceso   string `json:"acceso"`
		Refresco string `json:"refresco"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &tokens); err != nil {
		t.Fatalf("json de login: %v", err)
	}
	if tokens.Acceso == "" || tokens.Refresco == "" {
		t.Fatal("esperaba access y refresh")
	}

	// /auth/yo sin token → 401
	rec = pedir(t, s, http.MethodGet, "/auth/yo", nil, "")
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("/auth/yo sin token: código = %d, esperaba 401", rec.Code)
	}

	// /auth/yo con token → 200 con el email
	rec = pedir(t, s, http.MethodGet, "/auth/yo", nil, tokens.Acceso)
	if rec.Code != http.StatusOK {
		t.Fatalf("/auth/yo con token: código = %d, cuerpo = %s", rec.Code, rec.Body.String())
	}
	var yo struct {
		Email string `json:"email"`
	}
	_ = json.Unmarshal(rec.Body.Bytes(), &yo)
	if yo.Email != "tina@transi.test" {
		t.Fatalf("email = %q", yo.Email)
	}
}

func TestRegistroDuplicadoNoConfirmaQueElEmailExiste(t *testing.T) {
	s := nuevoServidorDePrueba(verificadorFalso{})
	cuerpo := []byte(`{"email":"tina@transi.test","clave":"secreto123"}`)
	primero := pedir(t, s, http.MethodPost, "/auth/registro", cuerpo, "")
	if primero.Code != http.StatusCreated {
		t.Fatalf("primer registro: %d", primero.Code)
	}

	// Registrar de nuevo el mismo email NO puede distinguirse del caso
	// normal por el código ni por el mensaje: si lo distinguiera, cualquiera
	// podría enumerar quién tiene cuenta (relevante en una app de salud).
	segundo := pedir(t, s, http.MethodPost, "/auth/registro", cuerpo, "")
	if segundo.Code != primero.Code {
		t.Fatalf("el registro duplicado cambió el código: %d vs %d",
			segundo.Code, primero.Code)
	}
	if !sonJSONIguales(primero.Body.Bytes(), segundo.Body.Bytes()) {
		t.Fatalf("el cuerpo difiere entre un registro válido y uno duplicado:\n nuevo:     %s\n duplicado: %s",
			primero.Body.String(), segundo.Body.String())
	}
}

// sonJSONIguales compara dos cuerpos JSON por estructura, sin importar el
// orden de las claves.
func sonJSONIguales(a, b []byte) bool {
	var x, y any
	if err := json.Unmarshal(a, &x); err != nil {
		return false
	}
	if err := json.Unmarshal(b, &y); err != nil {
		return false
	}
	return reflect.DeepEqual(x, y)
}

func TestLoginCredencialesInvalidas(t *testing.T) {
	s := nuevoServidorDePrueba(verificadorFalso{})
	_ = pedir(t, s, http.MethodPost, "/auth/registro",
		[]byte(`{"email":"tina@transi.test","clave":"secreto123"}`), "")
	rec := pedir(t, s, http.MethodPost, "/auth/login",
		[]byte(`{"email":"tina@transi.test","clave":"malamala"}`), "")
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("código = %d, esperaba 401", rec.Code)
	}
}
