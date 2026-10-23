package casosdeuso

import (
	"context"
	"time"

	"github.com/google/uuid"

	"transi/internal/dominio"
	"transi/internal/puertos"
)

// EntradaTratamiento es lo que llega al crear o editar (U8/U9).
type EntradaTratamiento struct {
	Nombre      string
	Dosis       string
	Frecuencia  string
	FechaInicio time.Time
	FechaFin    *time.Time

	// Opcionales.
	Via                     *string
	Presentacion            *string
	DosisCantidad           *float64
	DosisUnidad             *string
	Indicacion              *string
	ProfesionalNombre       *string
	ProfesionalEspecialidad *string
}

// Tratamientos agrupa los casos de uso U8–U11.
type Tratamientos struct {
	repo puertos.TratamientoRepositorio
}

func NuevoTratamientos(repo puertos.TratamientoRepositorio) Tratamientos {
	return Tratamientos{repo: repo}
}

// U8 · Crear tratamiento (R2, R6).
func (c Tratamientos) Crear(ctx context.Context, usuarioID string, e EntradaTratamiento) (dominio.Tratamiento, error) {
	t := dominio.Tratamiento{
		ID:                      uuid.NewString(),
		UsuarioID:               usuarioID,
		Nombre:                  e.Nombre,
		Dosis:                   e.Dosis,
		Frecuencia:              e.Frecuencia,
		FechaInicio:             e.FechaInicio,
		FechaFin:                e.FechaFin,
		Activo:                  true,
		Via:                     e.Via,
		Presentacion:            e.Presentacion,
		DosisCantidad:           e.DosisCantidad,
		DosisUnidad:             e.DosisUnidad,
		Indicacion:              e.Indicacion,
		ProfesionalNombre:       e.ProfesionalNombre,
		ProfesionalEspecialidad: e.ProfesionalEspecialidad,
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
	t.Nombre = e.Nombre
	t.Dosis = e.Dosis
	t.Frecuencia = e.Frecuencia
	t.FechaInicio = e.FechaInicio
	t.FechaFin = e.FechaFin
	t.Via = e.Via
	t.Presentacion = e.Presentacion
	t.DosisCantidad = e.DosisCantidad
	t.DosisUnidad = e.DosisUnidad
	t.Indicacion = e.Indicacion
	t.ProfesionalNombre = e.ProfesionalNombre
	t.ProfesionalEspecialidad = e.ProfesionalEspecialidad
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
