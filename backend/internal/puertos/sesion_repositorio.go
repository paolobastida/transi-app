package puertos

import (
	"context"

	"transi/internal/dominio"
)

// SesionRepositorio guarda y revoca los refresh tokens en el servidor.
type SesionRepositorio interface {
	Guardar(ctx context.Context, s dominio.Sesion) error
	// BuscarPorHash devuelve ErrNoEncontrado si no existe.
	BuscarPorHash(ctx context.Context, hash string) (*dominio.Sesion, error)
	// Borrar devuelve ErrNoEncontrado si no había nada que borrar.
	Borrar(ctx context.Context, hash string) error
}
