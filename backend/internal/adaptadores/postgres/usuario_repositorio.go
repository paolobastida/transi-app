package postgres

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"

	"transi/internal/dominio"
	"transi/internal/puertos"
)

// UsuarioRepositorio implementa puertos.UsuarioRepositorio sobre PostgreSQL.
type UsuarioRepositorio struct {
	conexion *Conexion
}

func NuevoUsuarioRepositorio(c *Conexion) *UsuarioRepositorio {
	return &UsuarioRepositorio{conexion: c}
}

func (r *UsuarioRepositorio) Crear(ctx context.Context, u dominio.Usuario) error {
	_, err := r.conexion.pool.Exec(ctx,
		`INSERT INTO users (id, email, password_hash, created_at)
		 VALUES ($1, $2, $3, $4)`,
		u.ID, u.Email, u.HashContrasena, u.FechaRegistro,
	)
	return err
}

func (r *UsuarioRepositorio) BuscarPorEmail(ctx context.Context, email string) (*dominio.Usuario, error) {
	var u dominio.Usuario
	err := r.conexion.pool.QueryRow(ctx,
		`SELECT id, email, password_hash, created_at
		 FROM users WHERE email = $1`,
		email,
	).Scan(&u.ID, &u.Email, &u.HashContrasena, &u.FechaRegistro)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, puertos.ErrNoEncontrado
	}
	if err != nil {
		return nil, err
	}
	return &u, nil
}
