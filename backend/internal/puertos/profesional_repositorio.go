package puertos

import (
	"context"

	"transi/internal/dominio"
)

// ProfesionalRepositorio guarda las fichas del equipo médico.
// Todas las operaciones filtran por usuarioId (R1).
type ProfesionalRepositorio interface {
	Crear(ctx context.Context, p dominio.Profesional) error
	ListarPorUsuario(ctx context.Context, usuarioID string) ([]dominio.Profesional, error)
	// BuscarPorID devuelve ErrNoEncontrado si no existe o no es del usuario.
	BuscarPorID(ctx context.Context, id, usuarioID string) (*dominio.Profesional, error)
	// Actualizar devuelve ErrNoEncontrado si no existe o no es del usuario.
	Actualizar(ctx context.Context, p dominio.Profesional) error
	// Desactivar hace borrado lógico (R5).
	Desactivar(ctx context.Context, id, usuarioID string) error
}
