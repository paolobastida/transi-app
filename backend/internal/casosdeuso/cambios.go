package casosdeuso

import (
	"context"
	"io"
	"time"

	"github.com/google/uuid"

	"transi/internal/dominio"
	"transi/internal/puertos"
)

// EntradaAdjunto es un archivo que llega junto a un cambio.
type EntradaAdjunto struct {
	Tipo      dominio.TipoAdjunto
	Nombre    string
	Contenido io.Reader
}

// EntradaCambio es lo que llega al registrar o editar un cambio (U12/U14).
type EntradaCambio struct {
	Fecha       time.Time
	Descripcion string
	Adjuntos    []EntradaAdjunto
}

// Cambios agrupa los casos de uso U12–U14.
type Cambios struct {
	repo     puertos.CambioRepositorio
	archivos puertos.ArchivoAlmacen
	ahora    func() time.Time
}

func NuevosCambios(repo puertos.CambioRepositorio, archivos puertos.ArchivoAlmacen) Cambios {
	return Cambios{repo: repo, archivos: archivos, ahora: time.Now}
}

// U12 · Registrar cambio (R3, R4). Orquesta ArchivoAlmacen + repositorio.
//
// Orden y compensación (architecture.md §3): primero se suben los archivos;
// si algo falla después, se borran los archivos ya subidos para no dejar
// huérfanos.
func (c Cambios) Registrar(ctx context.Context, usuarioID string, e EntradaCambio) (dominio.Cambio, error) {
	var subidos []string
	for _, entrada := range e.Adjuntos {
		referencia, err := c.archivos.Subir(ctx, entrada.Nombre, entrada.Contenido)
		if err != nil {
			c.compensar(ctx, subidos)
			return dominio.Cambio{}, err
		}
		subidos = append(subidos, referencia)
	}

	cambio := dominio.Cambio{
		ID:          uuid.NewString(),
		UsuarioID:   usuarioID,
		Fecha:       e.Fecha,
		Descripcion: e.Descripcion,
		Activo:      true,
	}
	for i, entrada := range e.Adjuntos {
		cambio.Adjuntos = append(cambio.Adjuntos, dominio.Adjunto{
			ID:       uuid.NewString(),
			CambioID: cambio.ID,
			Tipo:     entrada.Tipo,
			Archivo:  subidos[i],
		})
	}

	if err := cambio.Validar(c.ahora()); err != nil {
		c.compensar(ctx, subidos)
		return dominio.Cambio{}, err
	}
	if err := c.repo.Crear(ctx, cambio); err != nil {
		c.compensar(ctx, subidos)
		return dominio.Cambio{}, err
	}
	return cambio, nil
}

// U13 · Listar cambios por rango de fechas.
func (c Cambios) Listar(ctx context.Context, usuarioID string, filtro puertos.FiltroCambios) ([]dominio.Cambio, error) {
	return c.repo.ListarPorUsuario(ctx, usuarioID, filtro)
}

// U14 · Editar cambio (R3 y R4 también al editar). No cambia los adjuntos.
func (c Cambios) Editar(ctx context.Context, usuarioID, id string, fecha time.Time, descripcion string) (dominio.Cambio, error) {
	cambio, err := c.repo.BuscarPorID(ctx, id, usuarioID)
	if err != nil {
		return dominio.Cambio{}, err
	}
	cambio.Fecha = fecha
	cambio.Descripcion = descripcion
	if err := cambio.Validar(c.ahora()); err != nil {
		return dominio.Cambio{}, err
	}
	if err := c.repo.Actualizar(ctx, *cambio); err != nil {
		return dominio.Cambio{}, err
	}
	return *cambio, nil
}

// U14 · Desactivar cambio (R5: borrado lógico).
func (c Cambios) Desactivar(ctx context.Context, usuarioID, id string) error {
	return c.repo.Desactivar(ctx, id, usuarioID)
}

func (c Cambios) compensar(ctx context.Context, referencias []string) {
	for _, referencia := range referencias {
		_ = c.archivos.Borrar(ctx, referencia)
	}
}
