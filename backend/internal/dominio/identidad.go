package dominio

import (
	"errors"
	"net/mail"
)

// Errores de identidad. Los adaptadores (HTTP) los traducen a la respuesta
// que corresponde; el núcleo no sabe de códigos HTTP.
var (
	ErrEmailInvalido   = errors.New("el email no es válido")
	ErrContrasenaCorta = errors.New("la contraseña debe tener al menos 8 caracteres")
)

// ValidarEmail exige una dirección simple (sin nombre para mostrar).
func ValidarEmail(email string) error {
	direccion, err := mail.ParseAddress(email)
	if err != nil || direccion.Address != email {
		return ErrEmailInvalido
	}
	return nil
}

// ValidarContrasena aplica la longitud mínima del MVP (≥ 8).
func ValidarContrasena(clave string) error {
	if len([]rune(clave)) < 8 {
		return ErrContrasenaCorta
	}
	return nil
}
