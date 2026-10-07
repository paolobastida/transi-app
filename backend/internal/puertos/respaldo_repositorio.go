package puertos

import (
	"context"

	"transi/internal/dominio"
)

// RespaldoRepositorio guarda la referencia de cada respaldo (el contenido vive
// en el ArchivoAlmacen). Filtra por usuarioId (R1).
type RespaldoRepositorio interface {
	Crear(ctx context.Context, r dominio.Respaldo) error
	// Ultimo devuelve ErrNoEncontrado si el usuario no tiene respaldos.
	Ultimo(ctx context.Context, usuarioID string) (*dominio.Respaldo, error)
	ListarPorUsuario(ctx context.Context, usuarioID string) ([]dominio.Respaldo, error)
}
