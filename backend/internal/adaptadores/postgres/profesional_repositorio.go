package postgres

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"

	"transi/internal/dominio"
	"transi/internal/puertos"
)

// ProfesionalRepositorio implementa puertos.ProfesionalRepositorio.
type ProfesionalRepositorio struct {
	conexion *Conexion
}

func NuevoProfesionalRepositorio(c *Conexion) *ProfesionalRepositorio {
	return &ProfesionalRepositorio{conexion: c}
}

func (r *ProfesionalRepositorio) Crear(ctx context.Context, p dominio.Profesional) error {
	_, err := r.conexion.pool.Exec(ctx,
		`INSERT INTO profesionales (id, usuario_id, nombre, especialidad, activo)
		 VALUES ($1, $2, $3, $4, $5)`,
		p.ID, p.UsuarioID, p.Nombre, p.Especialidad, p.Activo,
	)
	return err
}

func (r *ProfesionalRepositorio) ListarPorUsuario(ctx context.Context, usuarioID string) ([]dominio.Profesional, error) {
	filas, err := r.conexion.pool.Query(ctx,
		`SELECT id, usuario_id, nombre, especialidad, activo
		 FROM profesionales WHERE usuario_id = $1 AND activo = true
		 ORDER BY nombre`, usuarioID,
	)
	if err != nil {
		return nil, err
	}
	defer filas.Close()

	var profesionales []dominio.Profesional
	for filas.Next() {
		var p dominio.Profesional
		if err := filas.Scan(&p.ID, &p.UsuarioID, &p.Nombre, &p.Especialidad, &p.Activo); err != nil {
			return nil, err
		}
		profesionales = append(profesionales, p)
	}
	return profesionales, filas.Err()
}

func (r *ProfesionalRepositorio) BuscarPorID(ctx context.Context, id, usuarioID string) (*dominio.Profesional, error) {
	var p dominio.Profesional
	err := r.conexion.pool.QueryRow(ctx,
		`SELECT id, usuario_id, nombre, especialidad, activo
		 FROM profesionales WHERE id = $1 AND usuario_id = $2`,
		id, usuarioID,
	).Scan(&p.ID, &p.UsuarioID, &p.Nombre, &p.Especialidad, &p.Activo)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, puertos.ErrNoEncontrado
	}
	if err != nil {
		return nil, err
	}
	return &p, nil
}

func (r *ProfesionalRepositorio) Actualizar(ctx context.Context, p dominio.Profesional) error {
	etiqueta, err := r.conexion.pool.Exec(ctx,
		`UPDATE profesionales SET nombre = $1, especialidad = $2
		 WHERE id = $3 AND usuario_id = $4`,
		p.Nombre, p.Especialidad, p.ID, p.UsuarioID,
	)
	if err != nil {
		return err
	}
	if etiqueta.RowsAffected() == 0 {
		return puertos.ErrNoEncontrado
	}
	return nil
}

func (r *ProfesionalRepositorio) Desactivar(ctx context.Context, id, usuarioID string) error {
	etiqueta, err := r.conexion.pool.Exec(ctx,
		`UPDATE profesionales SET activo = false
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
