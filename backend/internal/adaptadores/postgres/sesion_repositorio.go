package postgres

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"

	"transi/internal/dominio"
	"transi/internal/puertos"
)

// SesionRepositorio implementa puertos.SesionRepositorio sobre PostgreSQL.
type SesionRepositorio struct {
	conexion *Conexion
}

func NuevoSesionRepositorio(c *Conexion) *SesionRepositorio {
	return &SesionRepositorio{conexion: c}
}

func (r *SesionRepositorio) Guardar(ctx context.Context, s dominio.Sesion) error {
	_, err := r.conexion.pool.Exec(ctx,
		`INSERT INTO sessions (id, user_id, token_hash, expires_at, created_at)
		 VALUES ($1, $2, $3, $4, $5)`,
		s.ID, s.UsuarioID, s.HashToken, s.ExpiraEn, s.CreadoEn,
	)
	return err
}

func (r *SesionRepositorio) BuscarPorHash(ctx context.Context, hash string) (*dominio.Sesion, error) {
	var s dominio.Sesion
	err := r.conexion.pool.QueryRow(ctx,
		`SELECT id, user_id, token_hash, expires_at, created_at
		 FROM sessions WHERE token_hash = $1`,
		hash,
	).Scan(&s.ID, &s.UsuarioID, &s.HashToken, &s.ExpiraEn, &s.CreadoEn)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, puertos.ErrNoEncontrado
	}
	if err != nil {
		return nil, err
	}
	return &s, nil
}

func (r *SesionRepositorio) Borrar(ctx context.Context, hash string) error {
	etiqueta, err := r.conexion.pool.Exec(ctx,
		`DELETE FROM sessions WHERE token_hash = $1`, hash,
	)
	if err != nil {
		return err
	}
	if etiqueta.RowsAffected() == 0 {
		return puertos.ErrNoEncontrado
	}
	return nil
}
