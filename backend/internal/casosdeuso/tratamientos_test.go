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

// tratamientosDePrueba devuelve el caso de uso y el repositorio falso de
// profesionales, para poder preparar profesionales desde el test.
func tratamientosDePrueba() (Tratamientos, *pruebas.ProfesionalesFalso) {
	profesionales := pruebas.NuevoProfesionalesFalso()
	return NuevoTratamientos(pruebas.NuevoTratamientosFalso(), profesionales), profesionales
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
	c, _ := tratamientosDePrueba()
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

func TestTratamientoFechasInvalidas(t *testing.T) {
	c, _ := tratamientosDePrueba()
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
	c, _ := tratamientosDePrueba()
	_, err := c.Crear(context.Background(), "u1", EntradaTratamiento{
		Nombre: "Estradiol", Frecuencia: "cada día", FechaInicio: fecha(t, "2026-01-01"),
	}) // falta la dosis → R6
	if !errors.Is(err, dominio.ErrTratamientoIncompleto) {
		t.Fatalf("esperaba ErrTratamientoIncompleto, obtuve %v", err)
	}
}

func TestProfesionalInvalidoEnTratamiento(t *testing.T) {
	c, _ := tratamientosDePrueba()
	inexistente := "no-existe"
	_, err := c.Crear(context.Background(), "u1", EntradaTratamiento{
		Nombre: "Estradiol", Dosis: "2 mg", Frecuencia: "cada día",
		FechaInicio: fecha(t, "2026-01-01"), ProfesionalID: &inexistente,
	})
	if !errors.Is(err, ErrProfesionalInvalido) {
		t.Fatalf("esperaba ErrProfesionalInvalido, obtuve %v", err)
	}
}

func TestProfesionalDeOtroUsuarioEsInvalido(t *testing.T) {
	c, profesionales := tratamientosDePrueba()
	ctx := context.Background()
	// Profesional creado para u1; u2 no puede usarlo.
	p, _ := NuevoProfesionales(profesionales).Crear(ctx, "u1", "Dra. López", "Endocrinología")
	_, err := c.Crear(ctx, "u2", EntradaTratamiento{
		Nombre: "Estradiol", Dosis: "2 mg", Frecuencia: "cada día",
		FechaInicio: fecha(t, "2026-01-01"), ProfesionalID: &p.ID,
	})
	if !errors.Is(err, ErrProfesionalInvalido) {
		t.Fatalf("esperaba ErrProfesionalInvalido, obtuve %v", err)
	}
}

func TestEditarCerrarYDesactivarTratamiento(t *testing.T) {
	c, _ := tratamientosDePrueba()
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
