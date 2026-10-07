package puertos

import (
	"context"
	"time"

	"transi/internal/dominio"
)

// FiltroTratamientos es la consulta opcional de U10 (por rango y/o estado).
type FiltroTratamientos struct {
	Desde  *time.Time
	Hasta  *time.Time
	Estado string // "", "activo" o "finalizado"
}

// TratamientoRepositorio guarda los tratamientos. Filtra por usuarioId (R1).
type TratamientoRepositorio interface {
	Crear(ctx context.Context, t dominio.Tratamiento) error
	ListarPorUsuario(ctx context.Context, usuarioID string, filtro FiltroTratamientos) ([]dominio.Tratamiento, error)
	// BuscarPorID devuelve ErrNoEncontrado si no existe o no es del usuario.
	BuscarPorID(ctx context.Context, id, usuarioID string) (*dominio.Tratamiento, error)
	// Actualizar devuelve ErrNoEncontrado si no existe o no es del usuario.
	Actualizar(ctx context.Context, t dominio.Tratamiento) error
	// Desactivar hace borrado lógico (R5).
	Desactivar(ctx context.Context, id, usuarioID string) error
}
