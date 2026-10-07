package puertos

import (
	"context"
	"io"
)

// ArchivoAlmacen guarda los binarios (fotos, audios, respaldos) y esconde si
// viven en disco o en la nube (ADR 005).
type ArchivoAlmacen interface {
	// Subir guarda el contenido y devuelve una referencia para recuperarlo.
	Subir(ctx context.Context, nombre string, contenido io.Reader) (referencia string, err error)
	Bajar(ctx context.Context, referencia string) (io.ReadCloser, error)
	Borrar(ctx context.Context, referencia string) error
}
