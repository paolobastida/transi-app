package postgres

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"

	"transi/internal/dominio"
	"transi/internal/puertos"
)

// CambioRepositorio implementa puertos.CambioRepositorio.
type CambioRepositorio struct {
	conexion *Conexion
}

func NuevoCambioRepositorio(c *Conexion) *CambioRepositorio {
	return &CambioRepositorio{conexion: c}
}

const columnasCambio = `id, usuario_id, fecha, descripcion, activo`

// Crear guarda el cambio y sus adjuntos en una sola transacción: o se guardan
// todos, o no se guarda ninguno.
func (r *CambioRepositorio) Crear(ctx context.Context, c dominio.Cambio) error {
	tx, err := r.conexion.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback(ctx) }()

	if _, err := tx.Exec(ctx,
		`INSERT INTO cambios (id, usuario_id, fecha, descripcion, activo)
		 VALUES ($1, $2, $3, $4, $5)`,
		c.ID, c.UsuarioID, c.Fecha, c.Descripcion, c.Activo,
	); err != nil {
		return err
	}
	for _, a := range c.Adjuntos {
		if _, err := tx.Exec(ctx,
			`INSERT INTO adjuntos (id, cambio_id, tipo, archivo)
			 VALUES ($1, $2, $3, $4)`,
			a.ID, c.ID, string(a.Tipo), a.Archivo,
		); err != nil {
			return err
		}
	}
	return tx.Commit(ctx)
}

func (r *CambioRepositorio) ListarPorUsuario(ctx context.Context, usuarioID string, filtro puertos.FiltroCambios) ([]dominio.Cambio, error) {
	consulta := `SELECT ` + columnasCambio + `
		FROM cambios WHERE usuario_id = $1 AND activo = true`
	argumentos := []any{usuarioID}

	if filtro.Desde != nil {
		argumentos = append(argumentos, *filtro.Desde)
		consulta += fmt.Sprintf(" AND fecha >= $%d", len(argumentos))
	}
	if filtro.Hasta != nil {
		argumentos = append(argumentos, *filtro.Hasta)
		consulta += fmt.Sprintf(" AND fecha <= $%d", len(argumentos))
	}
	consulta += " ORDER BY fecha DESC"

	filas, err := r.conexion.pool.Query(ctx, consulta, argumentos...)
	if err != nil {
		return nil, err
	}
	defer filas.Close()

	var cambios []dominio.Cambio
	for filas.Next() {
		var c dominio.Cambio
		if err := filas.Scan(&c.ID, &c.UsuarioID, &c.Fecha, &c.Descripcion, &c.Activo); err != nil {
			return nil, err
		}
		cambios = append(cambios, c)
	}
	if err := filas.Err(); err != nil {
		return nil, err
	}
	for i := range cambios {
		adjuntos, err := r.adjuntosDe(ctx, cambios[i].ID)
		if err != nil {
			return nil, err
		}
		cambios[i].Adjuntos = adjuntos
	}
	return cambios, nil
}

func (r *CambioRepositorio) BuscarPorID(ctx context.Context, id, usuarioID string) (*dominio.Cambio, error) {
	var c dominio.Cambio
	err := r.conexion.pool.QueryRow(ctx,
		`SELECT `+columnasCambio+`
		 FROM cambios WHERE id = $1 AND usuario_id = $2`,
		id, usuarioID,
	).Scan(&c.ID, &c.UsuarioID, &c.Fecha, &c.Descripcion, &c.Activo)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, puertos.ErrNoEncontrado
	}
	if err != nil {
		return nil, err
	}
	adjuntos, err := r.adjuntosDe(ctx, c.ID)
	if err != nil {
		return nil, err
	}
	c.Adjuntos = adjuntos
	return &c, nil
}

func (r *CambioRepositorio) Actualizar(ctx context.Context, c dominio.Cambio) error {
	etiqueta, err := r.conexion.pool.Exec(ctx,
		`UPDATE cambios SET fecha = $1, descripcion = $2
		 WHERE id = $3 AND usuario_id = $4`,
		c.Fecha, c.Descripcion, c.ID, c.UsuarioID,
	)
	if err != nil {
		return err
	}
	if etiqueta.RowsAffected() == 0 {
		return puertos.ErrNoEncontrado
	}
	return nil
}

func (r *CambioRepositorio) Desactivar(ctx context.Context, id, usuarioID string) error {
	etiqueta, err := r.conexion.pool.Exec(ctx,
		`UPDATE cambios SET activo = false
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

func (r *CambioRepositorio) adjuntosDe(ctx context.Context, cambioID string) ([]dominio.Adjunto, error) {
	filas, err := r.conexion.pool.Query(ctx,
		`SELECT id, cambio_id, tipo, archivo
		 FROM adjuntos WHERE cambio_id = $1 ORDER BY creado_en`,
		cambioID,
	)
	if err != nil {
		return nil, err
	}
	defer filas.Close()

	var adjuntos []dominio.Adjunto
	for filas.Next() {
		var a dominio.Adjunto
		var tipo string
		if err := filas.Scan(&a.ID, &a.CambioID, &tipo, &a.Archivo); err != nil {
			return nil, err
		}
		a.Tipo = dominio.TipoAdjunto(tipo)
		adjuntos = append(adjuntos, a)
	}
	return adjuntos, filas.Err()
}
