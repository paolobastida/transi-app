package casosdeuso

import (
	"context"
	"errors"
	"testing"

	"transi/internal/dominio"
	"transi/internal/pruebas"
	"transi/internal/puertos"
)

func profesionalesDePrueba() Profesionales {
	return NuevoProfesionales(pruebas.NuevoProfesionalesFalso())
}

func TestCrearProfesional(t *testing.T) {
	c := profesionalesDePrueba()
	p, err := c.Crear(context.Background(), "u1", "Dra. López", "Endocrinología")
	if err != nil {
		t.Fatalf("crear: %v", err)
	}
	if p.ID == "" || !p.Activo {
		t.Fatalf("profesional inesperado: %+v", p)
	}
}

func TestCrearProfesionalIncompleto(t *testing.T) {
	c := profesionalesDePrueba()
	if _, err := c.Crear(context.Background(), "u1", "", "Endocrinología"); !errors.Is(err, dominio.ErrProfesionalIncompleto) {
		t.Fatalf("esperaba ErrProfesionalIncompleto, obtuve %v", err)
	}
}

func TestEditarYDesactivarProfesional(t *testing.T) {
	c := profesionalesDePrueba()
	ctx := context.Background()
	p, _ := c.Crear(ctx, "u1", "Dra. López", "Endocrinología")

	editado, err := c.Editar(ctx, "u1", p.ID, "Dra. López", "Endocrinología y diabetes")
	if err != nil {
		t.Fatalf("editar: %v", err)
	}
	if editado.Especialidad != "Endocrinología y diabetes" {
		t.Fatalf("no se actualizó la especialidad: %q", editado.Especialidad)
	}

	if err := c.Desactivar(ctx, "u1", p.ID); err != nil {
		t.Fatalf("desactivar: %v", err)
	}
	lista, err := c.Listar(ctx, "u1")
	if err != nil {
		t.Fatalf("listar: %v", err)
	}
	if len(lista) != 0 {
		t.Fatal("un profesional desactivado no debe listarse (R5)")
	}
}

func TestProfesionalDeOtroUsuarioNoSeEdita(t *testing.T) {
	c := profesionalesDePrueba()
	ctx := context.Background()
	p, _ := c.Crear(ctx, "u1", "Dra. López", "Endocrinología")

	if _, err := c.Editar(ctx, "u2", p.ID, "Intrusa", "Nada"); !errors.Is(err, puertos.ErrNoEncontrado) {
		t.Fatalf("esperaba ErrNoEncontrado, obtuve %v", err)
	}
	if err := c.Desactivar(ctx, "u2", p.ID); !errors.Is(err, puertos.ErrNoEncontrado) {
		t.Fatalf("esperaba ErrNoEncontrado, obtuve %v", err)
	}
}
