// Package postgres implementa los puertos de salida sobre PostgreSQL.
package postgres

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Conexion envuelve el pool de conexiones a PostgreSQL.
// Cumple puertos.VerificadorSalud mediante Ping.
type Conexion struct {
	pool *pgxpool.Pool
}

// NuevaConexion prepara el pool y verifica que la base responde.
func NuevaConexion(ctx context.Context, url string) (*Conexion, error) {
	cfg, err := pgxpool.ParseConfig(url)
	if err != nil {
		return nil, err
	}
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return nil, err
	}
	c := &Conexion{pool: pool}
	if err := c.Ping(ctx); err != nil {
		pool.Close()
		return nil, err
	}
	return c, nil
}

// Ping comprueba que la base responde, con un tope de dos segundos.
func (c *Conexion) Ping(ctx context.Context) error {
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	return c.pool.Ping(ctx)
}

// Cerrar libera todas las conexiones del pool.
func (c *Conexion) Cerrar() {
	c.pool.Close()
}
