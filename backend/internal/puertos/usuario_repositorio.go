package puertos

import (
	"context"

	"transi/internal/dominio"
)

// UsuarioRepositorio guarda y busca cuentas.
// La implementación concreta (Postgres, un falso de tests) vive en adaptadores.
type UsuarioRepositorio interface {
	Crear(ctx context.Context, u dominio.Usuario) error
	// BuscarPorEmail devuelve ErrNoEncontrado si no existe.
	BuscarPorEmail(ctx context.Context, email string) (*dominio.Usuario, error)
	// BuscarPorID devuelve ErrNoEncontrado si no existe.
	BuscarPorID(ctx context.Context, id string) (*dominio.Usuario, error)
}
