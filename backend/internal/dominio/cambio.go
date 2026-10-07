package dominio

import (
	"errors"
	"strings"
	"time"
)

// TipoAdjunto: un adjunto es una foto o una nota de voz (audio).
type TipoAdjunto string

const (
	TipoFoto  TipoAdjunto = "foto"
	TipoAudio TipoAdjunto = "audio"
)

var (
	// ErrFechaFutura: R3, un cambio no puede tener fecha futura.
	ErrFechaFutura = errors.New("un cambio no puede tener fecha futura")
	// ErrCambioVacio: R4, hace falta descripción no vacía o al menos un adjunto.
	ErrCambioVacio = errors.New("un cambio necesita una descripción o al menos un adjunto")
)

// Adjunto es un archivo pegado a un cambio. Archivo es la referencia que
// devuelve el ArchivoAlmacen (el contenido vive fuera de la base).
type Adjunto struct {
	ID       string
	CambioID string
	Tipo     TipoAdjunto
	Archivo  string
}

// Cambio es un hecho físico documentado en una fecha.
// Activo en false significa borrado lógico (R5).
type Cambio struct {
	ID          string
	UsuarioID   string
	Fecha       time.Time
	Descripcion string
	Activo      bool
	Adjuntos    []Adjunto
}

// Validar aplica R3 y R4. Recibe "ahora" para poder probar sin depender del reloj.
func (c Cambio) Validar(ahora time.Time) error {
	if soloFecha(c.Fecha).After(soloFecha(ahora)) {
		return ErrFechaFutura
	}
	if strings.TrimSpace(c.Descripcion) == "" && len(c.Adjuntos) == 0 {
		return ErrCambioVacio
	}
	return nil
}

func soloFecha(t time.Time) time.Time {
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC)
}
