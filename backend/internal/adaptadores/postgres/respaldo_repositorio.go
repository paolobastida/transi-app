package postgres

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"

	"transi/internal/dominio"
	"transi/internal/puertos"
)

// RespaldoRepositorio implementa puertos.RespaldoRepositorio.
type RespaldoRepositorio struct {
	conexion *Conexion
}

func NuevoRespaldoRepositorio(c *Conexion) *RespaldoRepositorio {
	return &RespaldoRepositorio{conexion: c}
}

func (r *RespaldoRepositorio) Crear(ctx context.Context, respaldo dominio.Respaldo) error {
	_, err := r.conexion.pool.Exec(ctx,
		`INSERT INTO respaldos (id, usuario_id, archivo, creado_en)
		 VALUES ($1, $2, $3, $4)`,
		respaldo.ID, respaldo.UsuarioID, respaldo.Archivo, respaldo.CreadoEn,
	)
	return err
}

func (r *RespaldoRepositorio) Ultimo(ctx context.Context, usuarioID string) (*dominio.Respaldo, error) {
	var respaldo dominio.Respaldo
	err := r.conexion.pool.QueryRow(ctx,
		`SELECT id, usuario_id, archivo, creado_en
		 FROM respaldos WHERE usuario_id = $1
		 ORDER BY creado_en DESC LIMIT 1`,
		usuarioID,
	).Scan(&respaldo.ID, &respaldo.UsuarioID, &respaldo.Archivo, &respaldo.CreadoEn)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, puertos.ErrNoEncontrado
	}
	if err != nil {
		return nil, err
	}
	return &respaldo, nil
}

func (r *RespaldoRepositorio) ListarPorUsuario(ctx context.Context, usuarioID string) ([]dominio.Respaldo, error) {
	filas, err := r.conexion.pool.Query(ctx,
		`SELECT id, usuario_id, archivo, creado_en
		 FROM respaldos WHERE usuario_id = $1
		 ORDER BY creado_en DESC`,
		usuarioID,
	)
	if err != nil {
		return nil, err
	}
	defer filas.Close()

	var respaldos []dominio.Respaldo
	for filas.Next() {
		var respaldo dominio.Respaldo
		if err := filas.Scan(&respaldo.ID, &respaldo.UsuarioID, &respaldo.Archivo, &respaldo.CreadoEn); err != nil {
			return nil, err
		}
		respaldos = append(respaldos, respaldo)
	}
	return respaldos, filas.Err()
}
