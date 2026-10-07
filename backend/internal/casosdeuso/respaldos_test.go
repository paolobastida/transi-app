package casosdeuso

import (
	"context"
	"errors"
	"io"
	"strings"
	"testing"
	"time"

	"transi/internal/pruebas"
	"transi/internal/puertos"
)

func respaldosDePrueba(t *testing.T) (Respaldos, *pruebas.RespaldosFalso, *pruebas.ArchivosFalso) {
	t.Helper()
	repo := pruebas.NuevoRespaldosFalso()
	archivos := pruebas.NuevoArchivosFalso()
	c := NuevosRespaldos(repo, archivos)
	c.ahora = func() time.Time { return fecha(t, "2026-01-15") }
	return c, repo, archivos
}

func TestRespaldarYRestaurar(t *testing.T) {
	c, _, _ := respaldosDePrueba(t)
	ctx := context.Background()
	contenido := `{"profesionales":[],"tratamientos":[],"cambios":[]}`

	if _, err := c.Respaldar(ctx, "u1", strings.NewReader(contenido)); err != nil {
		t.Fatalf("respaldar: %v", err)
	}
	lector, _, err := c.Restaurar(ctx, "u1")
	if err != nil {
		t.Fatalf("restaurar: %v", err)
	}
	defer lector.Close()

	datos, err := io.ReadAll(lector)
	if err != nil {
		t.Fatalf("leer respaldo: %v", err)
	}
	if string(datos) != contenido {
		t.Fatalf("el respaldo no volvió idéntico: %q", string(datos))
	}
}

func TestRestaurarSinRespaldos(t *testing.T) {
	c, _, _ := respaldosDePrueba(t)
	if _, _, err := c.Restaurar(context.Background(), "u1"); !errors.Is(err, puertos.ErrNoEncontrado) {
		t.Fatalf("esperaba ErrNoEncontrado, obtuve %v", err)
	}
}

func TestCompensacionSiFallaGuardarRespaldo(t *testing.T) {
	c, repo, archivos := respaldosDePrueba(t)
	repo.FallaAlCrear = true
	if _, err := c.Respaldar(context.Background(), "u1", strings.NewReader("x")); err == nil {
		t.Fatal("esperaba error al guardar el respaldo")
	}
	if len(archivos.PorReferencia) != 0 {
		t.Fatal("no debe quedar archivo huérfano")
	}
}
