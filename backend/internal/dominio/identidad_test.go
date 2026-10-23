package dominio

import (
	"errors"
	"strings"
	"testing"
)

func TestValidarEmail(t *testing.T) {
	if err := ValidarEmail("tina@transi.test"); err != nil {
		t.Fatalf("email válido rechazado: %v", err)
	}
	for _, malo := range []string{"", "no-es-email", "Tina <tina@transi.test>"} {
		if err := ValidarEmail(malo); !errors.Is(err, ErrEmailInvalido) {
			t.Errorf("esperaba ErrEmailInvalido para %q, obtuve %v", malo, err)
		}
	}
}

func TestValidarContrasena(t *testing.T) {
	if err := ValidarContrasena("secreto123"); err != nil {
		t.Fatalf("contraseña válida rechazada: %v", err)
	}
	if err := ValidarContrasena("corta"); !errors.Is(err, ErrContrasenaCorta) {
		t.Fatalf("esperaba ErrContrasenaCorta, obtuve %v", err)
	}
}

// bcrypt solo usa los primeros 72 bytes: >72 debe rechazarse con un error de
// dominio (400), no llegar nunca a bcrypt (que devolvería un error → 500).
func TestValidarContrasenaDemasiadoLarga(t *testing.T) {
	justa := strings.Repeat("A", 72)
	if err := ValidarContrasena(justa); err != nil {
		t.Fatalf("72 bytes debería ser válido: %v", err)
	}
	larga := strings.Repeat("A", 73)
	if err := ValidarContrasena(larga); !errors.Is(err, ErrContrasenaLarga) {
		t.Fatalf("esperaba ErrContrasenaLarga para 73 bytes, obtuve %v", err)
	}
}
