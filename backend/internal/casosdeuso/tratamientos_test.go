package casosdeuso

import (
	"context"
	"errors"
	"testing"
	"time"

	"transi/internal/dominio"
	"transi/internal/pruebas"
	"transi/internal/puertos"
)

func tratamientosDePrueba() Tratamientos {
	return NuevoTratamientos(pruebas.NuevoTratamientosFalso())
}

func fecha(t *testing.T, valor string) time.Time {
	t.Helper()
	f, err := time.Parse("2006-01-02", valor)
	if err != nil {
		t.Fatalf("fecha de prueba inválida %q: %v", valor, err)
	}
	return f
}

func TestCrearTratamiento(t *testing.T) {
	c := tratamientosDePrueba()
	inicio := fecha(t, "2026-01-10")
	tr, err := c.Crear(context.Background(), "u1", EntradaTratamiento{
		Nombre: "Estradiol", Dosis: "2 mg", Frecuencia: "cada día", FechaInicio: inicio,
	})
	if err != nil {
		t.Fatalf("crear: %v", err)
	}
	if tr.Finalizado() {
		t.Fatal("un tratamiento sin fecha de fin debe estar activo")
	}
}

func TestCrearTratamientoConProfesionalInline(t *testing.T) {
	c := tratamientosDePrueba()
	nombre := "Dra. García"
	especialidad := "Endocrinología"
	tr, err := c.Crear(context.Background(), "u1", EntradaTratamiento{
		Nombre: "Estradiol", Dosis: "2 mg", Frecuencia: "cada día",
		FechaInicio:             fecha(t, "2026-01-10"),
		ProfesionalNombre:       &nombre,
		ProfesionalEspecialidad: &especialidad,
	})
	if err != nil {
		t.Fatalf("crear: %v", err)
	}
	if tr.ProfesionalNombre == nil || *tr.ProfesionalNombre != nombre {
		t.Fatalf("profesionalNombre = %v, esperaba %q", tr.ProfesionalNombre, nombre)
	}
	if tr.ProfesionalEspecialidad == nil || *tr.ProfesionalEspecialidad != especialidad {
		t.Fatalf("profesionalEspecialidad = %v, esperaba %q", tr.ProfesionalEspecialidad, especialidad)
	}
}

func TestTratamientoFechasInvalidas(t *testing.T) {
	c := tratamientosDePrueba()
	inicio := fecha(t, "2026-03-01")
	fin := fecha(t, "2026-02-01") // antes del inicio → R2
	_, err := c.Crear(context.Background(), "u1", EntradaTratamiento{
		Nombre: "Estradiol", Dosis: "2 mg", Frecuencia: "cada día",
		FechaInicio: inicio, FechaFin: &fin,
	})
	if !errors.Is(err, dominio.ErrFechasInvalidas) {
		t.Fatalf("esperaba ErrFechasInvalidas, obtuve %v", err)
	}
}

func TestTratamientoIncompleto(t *testing.T) {
	c := tratamientosDePrueba()
	_, err := c.Crear(context.Background(), "u1", EntradaTratamiento{
		Nombre: "Estradiol", Frecuencia: "cada día", FechaInicio: fecha(t, "2026-01-01"),
	}) // falta la dosis → R6
	if !errors.Is(err, dominio.ErrTratamientoIncompleto) {
		t.Fatalf("esperaba ErrTratamientoIncompleto, obtuve %v", err)
	}
}

func TestEditarCerrarYDesactivarTratamiento(t *testing.T) {
	c := tratamientosDePrueba()
	ctx := context.Background()
	tr, _ := c.Crear(ctx, "u1", EntradaTratamiento{
		Nombre: "Estradiol", Dosis: "2 mg", Frecuencia: "cada día", FechaInicio: fecha(t, "2026-01-01"),
	})

	fin := fecha(t, "2026-06-01")
	cerrado, err := c.Editar(ctx, "u1", tr.ID, EntradaTratamiento{
		Nombre: "Estradiol", Dosis: "2 mg", Frecuencia: "cada día",
		FechaInicio: fecha(t, "2026-01-01"), FechaFin: &fin,
	})
	if err != nil {
		t.Fatalf("editar: %v", err)
	}
	if !cerrado.Finalizado() {
		t.Fatal("con fecha de fin debe quedar finalizado")
	}

	if err := c.Desactivar(ctx, "u1", tr.ID); err != nil {
		t.Fatalf("desactivar: %v", err)
	}
	lista, _ := c.Listar(ctx, "u1", puertos.FiltroTratamientos{})
	if len(lista) != 0 {
		t.Fatal("un tratamiento desactivado no debe listarse (R5)")
	}
}
