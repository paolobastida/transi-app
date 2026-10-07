package postgres

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"

	"transi/internal/dominio"
	"transi/internal/puertos"
)

// TratamientoRepositorio implementa puertos.TratamientoRepositorio.
type TratamientoRepositorio struct {
	conexion *Conexion
}

func NuevoTratamientoRepositorio(c *Conexion) *TratamientoRepositorio {
	return &TratamientoRepositorio{conexion: c}
}

const columnasTratamiento = `id, usuario_id, nombre, dosis, frecuencia,
	fecha_inicio, fecha_fin, profesional_id, activo`

func (r *TratamientoRepositorio) Crear(ctx context.Context, t dominio.Tratamiento) error {
	_, err := r.conexion.pool.Exec(ctx,
		`INSERT INTO tratamientos
		 (id, usuario_id, nombre, dosis, frecuencia, fecha_inicio, fecha_fin, profesional_id, activo)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
		t.ID, t.UsuarioID, t.Nombre, t.Dosis, t.Frecuencia,
		t.FechaInicio, t.FechaFin, t.ProfesionalID, t.Activo,
	)
	return err
}

func (r *TratamientoRepositorio) ListarPorUsuario(ctx context.Context, usuarioID string, filtro puertos.FiltroTratamientos) ([]dominio.Tratamiento, error) {
	consulta := `SELECT ` + columnasTratamiento + `
		FROM tratamientos WHERE usuario_id = $1 AND activo = true`
	argumentos := []any{usuarioID}

	if filtro.Desde != nil {
		argumentos = append(argumentos, *filtro.Desde)
		consulta += fmt.Sprintf(" AND fecha_inicio >= $%d", len(argumentos))
	}
	if filtro.Hasta != nil {
		argumentos = append(argumentos, *filtro.Hasta)
		consulta += fmt.Sprintf(" AND fecha_inicio <= $%d", len(argumentos))
	}
	switch filtro.Estado {
	case "activo":
		consulta += " AND fecha_fin IS NULL"
	case "finalizado":
		consulta += " AND fecha_fin IS NOT NULL"
	}
	consulta += " ORDER BY fecha_inicio DESC"

	filas, err := r.conexion.pool.Query(ctx, consulta, argumentos...)
	if err != nil {
		return nil, err
	}
	defer filas.Close()

	var tratamientos []dominio.Tratamiento
	for filas.Next() {
		t, err := escanearTratamiento(filas)
		if err != nil {
			return nil, err
		}
		tratamientos = append(tratamientos, t)
	}
	return tratamientos, filas.Err()
}

func (r *TratamientoRepositorio) BuscarPorID(ctx context.Context, id, usuarioID string) (*dominio.Tratamiento, error) {
	fila := r.conexion.pool.QueryRow(ctx,
		`SELECT `+columnasTratamiento+`
		 FROM tratamientos WHERE id = $1 AND usuario_id = $2`,
		id, usuarioID,
	)
	t, err := escanearTratamiento(fila)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, puertos.ErrNoEncontrado
	}
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func (r *TratamientoRepositorio) Actualizar(ctx context.Context, t dominio.Tratamiento) error {
	etiqueta, err := r.conexion.pool.Exec(ctx,
		`UPDATE tratamientos
		 SET nombre = $1, dosis = $2, frecuencia = $3,
		     fecha_inicio = $4, fecha_fin = $5, profesional_id = $6
		 WHERE id = $7 AND usuario_id = $8`,
		t.Nombre, t.Dosis, t.Frecuencia, t.FechaInicio, t.FechaFin,
		t.ProfesionalID, t.ID, t.UsuarioID,
	)
	if err != nil {
		return err
	}
	if etiqueta.RowsAffected() == 0 {
		return puertos.ErrNoEncontrado
	}
	return nil
}

func (r *TratamientoRepositorio) Desactivar(ctx context.Context, id, usuarioID string) error {
	etiqueta, err := r.conexion.pool.Exec(ctx,
		`UPDATE tratamientos SET activo = false
		 WHERE id = $1 AND usuario_id = $2 AND activo = true`,
		id, usuarioID,
	)
	if err != nil {
		return err
	}
	if etiqueta.RowsAffected() == 0 {
		return puertos.ErrNoEncontrado
	}
	return nil
}

// escanearTratamiento lee una fila (de Query o QueryRow) a un Tratamiento.
func escanearTratamiento(fila pgx.Row) (dominio.Tratamiento, error) {
	var t dominio.Tratamiento
	err := fila.Scan(
		&t.ID, &t.UsuarioID, &t.Nombre, &t.Dosis, &t.Frecuencia,
		&t.FechaInicio, &t.FechaFin, &t.ProfesionalID, &t.Activo,
	)
	return t, err
}
