package dominio

import (
	"errors"
	"strings"
	"time"
)

var (
	// ErrTratamientoIncompleto: R6 exige nombre, dosis, frecuencia y fecha de inicio.
	ErrTratamientoIncompleto = errors.New("nombre, dosis, frecuencia y fecha de inicio son obligatorios")
	// ErrFechasInvalidas: R2 exige fechaFin ≥ fechaInicio.
	ErrFechasInvalidas = errors.New("la fecha de fin no puede ser anterior a la fecha de inicio")
)

// Tratamiento es lo que la persona consume/administra.
//
// El estado "activo/finalizado" NO se guarda: se deriva de FechaFin (nil = sigue
// activo). Activo en false significa borrado lógico (R5).
//
// Nombre, Dosis y Frecuencia son texto y siguen obligatorios (R6). Todo lo
// demás es opcional (punteros nil): vía, presentación, dosis estructurada,
// indicación, y el profesional que lo indicó (nombre + especialidad como
// texto, sin entidad aparte).
type Tratamiento struct {
	ID          string
	UsuarioID   string
	Nombre      string
	Dosis       string
	Frecuencia  string
	FechaInicio time.Time
	FechaFin    *time.Time
	Activo      bool

	// Opcionales.
	Via                     *string
	Presentacion            *string
	DosisCantidad           *float64
	DosisUnidad             *string
	Indicacion              *string
	ProfesionalNombre       *string
	ProfesionalEspecialidad *string
}

func (t Tratamiento) Validar() error {
	if strings.TrimSpace(t.Nombre) == "" ||
		strings.TrimSpace(t.Dosis) == "" ||
		strings.TrimSpace(t.Frecuencia) == "" ||
		t.FechaInicio.IsZero() {
		return ErrTratamientoIncompleto
	}
	if t.FechaFin != nil && t.FechaFin.Before(t.FechaInicio) {
		return ErrFechasInvalidas
	}
	return nil
}

// Finalizado indica si el tratamiento ya tiene fecha de fin.
func (t Tratamiento) Finalizado() bool { return t.FechaFin != nil }
