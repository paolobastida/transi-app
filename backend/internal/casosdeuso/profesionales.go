package casosdeuso

import (
	"context"

	"github.com/google/uuid"

	"transi/internal/dominio"
	"transi/internal/puertos"
)

// Profesionales agrupa los casos de uso U4–U7.
type Profesionales struct {
	repo puertos.ProfesionalRepositorio
}

func NuevoProfesionales(repo puertos.ProfesionalRepositorio) Profesionales {
	return Profesionales{repo: repo}
}

// U4 · Crear profesional.
func (c Profesionales) Crear(ctx context.Context, usuarioID, nombre, especialidad string) (dominio.Profesional, error) {
	p := dominio.Profesional{
		ID:           uuid.NewString(),
		UsuarioID:    usuarioID,
		Nombre:       nombre,
		Especialidad: especialidad,
		Activo:       true,
	}
	if err := p.Validar(); err != nil {
		return dominio.Profesional{}, err
	}
	if err := c.repo.Crear(ctx, p); err != nil {
		return dominio.Profesional{}, err
	}
	return p, nil
}

// U5 · Listar mis profesionales.
func (c Profesionales) Listar(ctx context.Context, usuarioID string) ([]dominio.Profesional, error) {
	return c.repo.ListarPorUsuario(ctx, usuarioID)
}

// U6 · Editar profesional.
func (c Profesionales) Editar(ctx context.Context, usuarioID, id, nombre, especialidad string) (dominio.Profesional, error) {
	p, err := c.repo.BuscarPorID(ctx, id, usuarioID)
	if err != nil {
		return dominio.Profesional{}, err
	}
	p.Nombre = nombre
	p.Especialidad = especialidad
	if err := p.Validar(); err != nil {
		return dominio.Profesional{}, err
	}
	if err := c.repo.Actualizar(ctx, *p); err != nil {
		return dominio.Profesional{}, err
	}
	return *p, nil
}

// U7 · Desactivar profesional (R5: borrado lógico).
func (c Profesionales) Desactivar(ctx context.Context, usuarioID, id string) error {
	return c.repo.Desactivar(ctx, id, usuarioID)
}
