package casosdeuso

import (
	"context"
	"errors"
	"testing"
)

type verificadorFalso struct{ err error }

func (v verificadorFalso) Ping(context.Context) error { return v.err }

func TestVerificarSaludOK(t *testing.T) {
	caso := NuevoVerificarSalud(verificadorFalso{})
	if err := caso.Ejecutar(context.Background()); err != nil {
		t.Fatalf("esperaba sin error, obtuve %v", err)
	}
}

func TestVerificarSaludPropagaError(t *testing.T) {
	falla := errors.New("sin conexión")
	caso := NuevoVerificarSalud(verificadorFalso{err: falla})
	if err := caso.Ejecutar(context.Background()); !errors.Is(err, falla) {
		t.Fatalf("esperaba %v, obtuve %v", falla, err)
	}
}
