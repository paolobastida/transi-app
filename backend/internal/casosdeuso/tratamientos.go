package casosdeuso

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"transi/internal/dominio"
	"transi/internal/puertos"
)

// ErrProfesionalInvalido: el profesional indicado no existe o no es del usuario.
var ErrProfesionalInvalido = errors.New("el profesional indicado no existe")

// EntradaTratamiento es lo que llega al crear o editar (U8/U9).
type EntradaTratamiento struct {
	Nombre        string
	Dosis         string
	Frecuencia    string
	FechaInicio   time.Time
	FechaFin      *time.Time
	ProfesionalID *string
}

// Tratamientos agrupa los casos de uso U8–U11.
type Tratamientos struct {
	repo          puertos.TratamientoRepositorio
	profesionales puertos.ProfesionalRepositorio
}

func NuevoTratamientos(repo puertos.TratamientoRepositorio, profesionales puertos.ProfesionalRepositorio) Tratamientos {
	return Tratamientos{repo: repo, profesionales: profesionales}
}

// U8 · Crear tratamiento (R2, R6, R7).
func (c Tratamientos) Crear(ctx context.Context, usuarioID string, e EntradaTratamiento) (dominio.Tratamiento, error) {
	if err := c.validarProfesional(ctx, usuarioID, e.ProfesionalID); err != nil {
		return dominio.Tratamiento{}, err
	}
	t := dominio.Tratamiento{
		ID:            uuid.NewString(),
		UsuarioID:     usuarioID,
		Nombre:        e.Nombre,
		Dosis:         e.Dosis,
		Frecuencia:    e.Frecuencia,
		FechaInicio:   e.FechaInicio,
		FechaFin:      e.FechaFin,
		ProfesionalID: e.ProfesionalID,
		Activo:        true,
	}
	if err := t.Validar(); err != nil {
		return dominio.Tratamiento{}, err
	}
	if err := c.repo.Crear(ctx, t); err != nil {
		return dominio.Tratamiento{}, err
	}
	return t, nil
}

// U10 · Listar tratamientos (opcional por rango y estado).
func (c Tratamientos) Listar(ctx context.Context, usuarioID string, filtro puertos.FiltroTratamientos) ([]dominio.Tratamiento, error) {
	return c.repo.ListarPorUsuario(ctx, usuarioID, filtro)
}

// U9 · Editar tratamiento (incluye cerrarlo poniendo fecha de fin). R2 al cambiar fechas.
func (c Tratamientos) Editar(ctx context.Context, usuarioID, id string, e EntradaTratamiento) (dominio.Tratamiento, error) {
	t, err := c.repo.BuscarPorID(ctx, id, usuarioID)
	if err != nil {
		return dominio.Tratamiento{}, err
	}
	if err := c.validarProfesional(ctx, usuarioID, e.ProfesionalID); err != nil {
		return dominio.Tratamiento{}, err
	}
	t.Nombre = e.Nombre
	t.Dosis = e.Dosis
	t.Frecuencia = e.Frecuencia
	t.FechaInicio = e.FechaInicio
	t.FechaFin = e.FechaFin
	t.ProfesionalID = e.ProfesionalID
	if err := t.Validar(); err != nil {
		return dominio.Tratamiento{}, err
	}
	if err := c.repo.Actualizar(ctx, *t); err != nil {
		return dominio.Tratamiento{}, err
	}
	return *t, nil
}

// U11 · Desactivar tratamiento (R5: borrado lógico).
func (c Tratamientos) Desactivar(ctx context.Context, usuarioID, id string) error {
	return c.repo.Desactivar(ctx, id, usuarioID)
}

// validarProfesional comprueba que un profesional opcional (R7) sea del usuario.
func (c Tratamientos) validarProfesional(ctx context.Context, usuarioID string, profesionalID *string) error {
	if profesionalID == nil || *profesionalID == "" {
		return nil
	}
	if _, err := c.profesionales.BuscarPorID(ctx, *profesionalID, usuarioID); err != nil {
		if errors.Is(err, puertos.ErrNoEncontrado) {
			return ErrProfesionalInvalido
		}
		return err
	}
	return nil
}
