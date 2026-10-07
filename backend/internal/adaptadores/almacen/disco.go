// Package almacen implementa puertos.ArchivoAlmacen sobre el disco local.
// Es el adaptador de desarrollo; en producción será el bucket (ADR 005).
package almacen

import (
	"context"
	"errors"
	"io"
	"os"
	"path/filepath"

	"github.com/google/uuid"
)

// Disco guarda los archivos dentro de una carpeta raíz.
type Disco struct {
	raiz string
}

func NuevoDisco(raiz string) (*Disco, error) {
	if err := os.MkdirAll(raiz, 0o755); err != nil {
		return nil, err
	}
	return &Disco{raiz: raiz}, nil
}

func (d *Disco) Subir(_ context.Context, nombre string, contenido io.Reader) (string, error) {
	// Referencia = nombre aleatorio + extensión original (evita colisiones).
	referencia := uuid.NewString() + filepath.Ext(nombre)
	destino := filepath.Join(d.raiz, referencia)

	archivo, err := os.Create(destino)
	if err != nil {
		return "", err
	}
	defer archivo.Close()

	if _, err := io.Copy(archivo, contenido); err != nil {
		_ = os.Remove(destino)
		return "", err
	}
	return referencia, nil
}

func (d *Disco) Bajar(_ context.Context, referencia string) (io.ReadCloser, error) {
	return os.Open(filepath.Join(d.raiz, filepath.Base(referencia)))
}

func (d *Disco) Borrar(_ context.Context, referencia string) error {
	err := os.Remove(filepath.Join(d.raiz, filepath.Base(referencia)))
	if errors.Is(err, os.ErrNotExist) {
		return nil
	}
	return err
}
