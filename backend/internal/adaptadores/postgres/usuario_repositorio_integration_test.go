package postgres

import (
	"context"
	"errors"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"

	"transi/internal/dominio"
	"transi/internal/puertos"
)

// TestUsuarioRepositorioIntegracion verifica el SQL real contra PostgreSQL.
// Solo corre si DATABASE_URL está definida (en local con docker-compose, y en
// CI con el servicio de Postgres). Si no, se salta: los tests rápidos no deben
// depender de Docker.
func TestUsuarioRepositorioIntegracion(t *testing.T) {
	url := os.Getenv("DATABASE_URL")
	if url == "" {
		t.Skip("sin DATABASE_URL: se omite la integración con PostgreSQL")
	}

	ctx := context.Background()
	bd, err := NuevaConexion(ctx, url)
	if err != nil {
		t.Fatalf("no se pudo conectar a PostgreSQL: %v", err)
	}
	defer bd.Cerrar()

	repo := NuevoUsuarioRepositorio(bd)
	email := "tina+" + uuid.NewString() + "@transi.test"
	u := dominio.Usuario{
		ID:             uuid.NewString(),
		Email:          email,
		HashContrasena: "$2a$10$hashsoloParaPrueba",
		FechaRegistro:  time.Now().UTC(),
	}
	defer func() {
		_, _ = bd.pool.Exec(ctx, `DELETE FROM users WHERE id = $1`, u.ID)
	}()

	if err := repo.Crear(ctx, u); err != nil {
		t.Fatalf("crear: %v", err)
	}

	obtenido, err := repo.BuscarPorEmail(ctx, email)
	if err != nil {
		t.Fatalf("buscar: %v", err)
	}
	if obtenido.ID != u.ID {
		t.Fatalf("id = %q, esperaba %q", obtenido.ID, u.ID)
	}
	if obtenido.Email != email {
		t.Fatalf("email = %q, esperaba %q", obtenido.Email, email)
	}

	duplicado := u
	duplicado.ID = uuid.NewString()
	if err := repo.Crear(ctx, duplicado); err == nil {
		t.Fatal("esperaba error al insertar un email duplicado")
	}

	if _, err := repo.BuscarPorEmail(ctx, "no-existe@transi.test"); !errors.Is(err, puertos.ErrNoEncontrado) {
		t.Fatalf("esperaba ErrNoEncontrado, obtuve %v", err)
	}
}
