package casosdeuso

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"transi/internal/dominio"
	"transi/internal/pruebas"
	"transi/internal/puertos"
)

func cambiosDePrueba(t *testing.T) (Cambios, *pruebas.CambiosFalso, *pruebas.ArchivosFalso) {
	t.Helper()
	repo := pruebas.NuevoCambiosFalso()
	archivos := pruebas.NuevoArchivosFalso()
	c := NuevosCambios(repo, archivos)
	c.ahora = func() time.Time { return fecha(t, "2026-01-15") }
	return c, repo, archivos
}

func adjuntoDePrueba(nombre string) EntradaAdjunto {
	return EntradaAdjunto{Tipo: dominio.TipoFoto, Nombre: nombre, Contenido: strings.NewReader("contenido")}
}

func TestRegistrarCambioConFoto(t *testing.T) {
	c, _, archivos := cambiosDePrueba(t)
	cambio, err := c.Registrar(context.Background(), "u1", EntradaCambio{
		Fecha:       fecha(t, "2026-01-10"),
		Descripcion: "noté cambios en la voz",
		Adjuntos:    []EntradaAdjunto{adjuntoDePrueba("voz.jpg")},
	})
	if err != nil {
		t.Fatalf("registrar: %v", err)
	}
	if len(cambio.Adjuntos) != 1 {
		t.Fatalf("esperaba 1 adjunto, hay %d", len(cambio.Adjuntos))
	}
	if len(archivos.PorReferencia) != 1 {
		t.Fatalf("esperaba 1 archivo guardado, hay %d", len(archivos.PorReferencia))
	}
}

func TestCambioConFechaFuturaSeCompensa(t *testing.T) {
	c, _, archivos := cambiosDePrueba(t)
	_, err := c.Registrar(context.Background(), "u1", EntradaCambio{
		Fecha:       fecha(t, "2026-02-01"), // futuro respecto del reloj de prueba
		Descripcion: "x",
		Adjuntos:    []EntradaAdjunto{adjuntoDePrueba("a.jpg")},
	})
	if !errors.Is(err, dominio.ErrFechaFutura) {
		t.Fatalf("esperaba ErrFechaFutura, obtuve %v", err)
	}
	if len(archivos.PorReferencia) != 0 {
		t.Fatal("el archivo subido debía borrarse (compensación)")
	}
}

func TestCambioVacio(t *testing.T) {
	c, _, _ := cambiosDePrueba(t)
	_, err := c.Registrar(context.Background(), "u1", EntradaCambio{Fecha: fecha(t, "2026-01-10")})
	if !errors.Is(err, dominio.ErrCambioVacio) {
		t.Fatalf("esperaba ErrCambioVacio, obtuve %v", err)
	}
}

func TestCompensacionSiFallaGuardarLaFicha(t *testing.T) {
	c, repo, archivos := cambiosDePrueba(t)
	repo.FallaAlCrear = true
	_, err := c.Registrar(context.Background(), "u1", EntradaCambio{
		Fecha:       fecha(t, "2026-01-10"),
		Descripcion: "x",
		Adjuntos:    []EntradaAdjunto{adjuntoDePrueba("a.jpg")},
	})
	if err == nil {
		t.Fatal("esperaba error al guardar la ficha")
	}
	if len(archivos.PorReferencia) != 0 {
		t.Fatal("no deben quedar archivos huérfanos")
	}
}

func TestFallaAlSubirNoDejaArchivos(t *testing.T) {
	c, _, archivos := cambiosDePrueba(t)
	archivos.FallaAlSubir = true
	_, err := c.Registrar(context.Background(), "u1", EntradaCambio{
		Fecha:       fecha(t, "2026-01-10"),
		Descripcion: "x",
		Adjuntos:    []EntradaAdjunto{adjuntoDePrueba("a.jpg")},
	})
	if err == nil {
		t.Fatal("esperaba error de almacenamiento")
	}
	if len(archivos.PorReferencia) != 0 {
		t.Fatal("no deben quedar archivos")
	}
}

func TestEditarCambioNoPuedeQuedarVacio(t *testing.T) {
	c, _, _ := cambiosDePrueba(t)
	ctx := context.Background()
	cambio, _ := c.Registrar(ctx, "u1", EntradaCambio{Fecha: fecha(t, "2026-01-10"), Descripcion: "algo"})

	if _, err := c.Editar(ctx, "u1", cambio.ID, fecha(t, "2026-01-10"), ""); !errors.Is(err, dominio.ErrCambioVacio) {
		t.Fatalf("esperaba ErrCambioVacio al editar, obtuve %v", err)
	}
}

func TestDesactivarCambio(t *testing.T) {
	c, _, _ := cambiosDePrueba(t)
	ctx := context.Background()
	cambio, _ := c.Registrar(ctx, "u1", EntradaCambio{Fecha: fecha(t, "2026-01-10"), Descripcion: "algo"})

	if err := c.Desactivar(ctx, "u1", cambio.ID); err != nil {
		t.Fatalf("desactivar: %v", err)
	}
	lista, _ := c.Listar(ctx, "u1", puertos.FiltroCambios{})
	if len(lista) != 0 {
		t.Fatal("un cambio desactivado no debe listarse (R5)")
	}
}
