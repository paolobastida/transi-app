package dominio

import (
	"errors"
	"strings"
)

// ErrProfesionalIncompleto: la ficha necesita nombre y especialidad.
var ErrProfesionalIncompleto = errors.New("el nombre y la especialidad son obligatorios")

// Profesional de salud es una ficha propia del equipo médico del usuario.
// Activo en false significa borrado lógico (R5): nunca se borra físicamente.
type Profesional struct {
	ID           string
	UsuarioID    string
	Nombre       string
	Especialidad string
	Activo       bool
}

func (p Profesional) Validar() error {
	if strings.TrimSpace(p.Nombre) == "" || strings.TrimSpace(p.Especialidad) == "" {
		return ErrProfesionalIncompleto
	}
	return nil
}
