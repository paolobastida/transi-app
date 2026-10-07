package puertos

import (
	"context"
	"time"

	"transi/internal/dominio"
)

// FiltroCambios es la consulta por rango de fechas de U13.
type FiltroCambios struct {
	Desde *time.Time
	Hasta *time.Time
}

// CambioRepositorio guarda cambios y sus adjuntos. Filtra por usuarioId (R1).
type CambioRepositorio interface {
	// Crear guarda el cambio y sus adjuntos en una sola transacción.
	Crear(ctx context.Context, c dominio.Cambio) error
	ListarPorUsuario(ctx context.Context, usuarioID string, filtro FiltroCambios) ([]dominio.Cambio, error)
	// BuscarPorID devuelve ErrNoEncontrado si no existe o no es del usuario.
	BuscarPorID(ctx context.Context, id, usuarioID string) (*dominio.Cambio, error)
	Actualizar(ctx context.Context, c dominio.Cambio) error
	// Desactivar hace borrado lógico (R5).
	Desactivar(ctx context.Context, id, usuarioID string) error
}
