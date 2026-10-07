package casosdeuso

import (
	"context"
	"io"
	"time"

	"github.com/google/uuid"

	"transi/internal/dominio"
	"transi/internal/puertos"
)

// Respaldos implementa U16 (respaldar / restaurar) del lado del servidor.
type Respaldos struct {
	repo     puertos.RespaldoRepositorio
	archivos puertos.ArchivoAlmacen
	ahora    func() time.Time
}

func NuevosRespaldos(repo puertos.RespaldoRepositorio, archivos puertos.ArchivoAlmacen) Respaldos {
	return Respaldos{repo: repo, archivos: archivos, ahora: time.Now}
}

// Respaldar guarda el contenido del respaldo. Si falla anotar la referencia,
// se borra el archivo subido (compensación).
func (c Respaldos) Respaldar(ctx context.Context, usuarioID string, contenido io.Reader) (dominio.Respaldo, error) {
	referencia, err := c.archivos.Subir(ctx, "respaldo.json", contenido)
	if err != nil {
		return dominio.Respaldo{}, err
	}
	respaldo := dominio.Respaldo{
		ID:        uuid.NewString(),
		UsuarioID: usuarioID,
		Archivo:   referencia,
		CreadoEn:  c.ahora().UTC(),
	}
	if err := c.repo.Crear(ctx, respaldo); err != nil {
		_ = c.archivos.Borrar(ctx, referencia)
		return dominio.Respaldo{}, err
	}
	return respaldo, nil
}

// Restaurar devuelve el contenido del último respaldo del usuario.
func (c Respaldos) Restaurar(ctx context.Context, usuarioID string) (io.ReadCloser, dominio.Respaldo, error) {
	respaldo, err := c.repo.Ultimo(ctx, usuarioID)
	if err != nil {
		return nil, dominio.Respaldo{}, err
	}
	lector, err := c.archivos.Bajar(ctx, respaldo.Archivo)
	if err != nil {
		return nil, dominio.Respaldo{}, err
	}
	return lector, *respaldo, nil
}

// Historial lista los respaldos del usuario (más reciente primero).
func (c Respaldos) Historial(ctx context.Context, usuarioID string) ([]dominio.Respaldo, error) {
	return c.repo.ListarPorUsuario(ctx, usuarioID)
}
