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
	// ErrContrasenaLarga: bcrypt solo usa los primeros 72 bytes de la clave. Si
	// aceptáramos más, dos claves que compartan esos 72 bytes serían
	// equivalentes (y bcrypt directamente falla al hashear >72 bytes). Se corta
	// en el dominio para que la API responda 400 y no un 500.
	ErrContrasenaLarga = errors.New("la contraseña es demasiado larga (máximo 72 bytes)")
)

// maximoBytesContrasena es el límite de bcrypt (72 bytes).
const maximoBytesContrasena = 72

// ValidarEmail exige una dirección simple (sin nombre para mostrar).
func ValidarEmail(email string) error {
	direccion, err := mail.ParseAddress(email)
	if err != nil || direccion.Address != email {
		return ErrEmailInvalido
	}
	return nil
}

// ValidarContrasena aplica la longitud mínima del MVP (≥ 8) y el máximo que
// tolera bcrypt (72 bytes).
func ValidarContrasena(clave string) error {
	if len([]rune(clave)) < 8 {
		return ErrContrasenaCorta
	}
	if len(clave) > maximoBytesContrasena {
		return ErrContrasenaLarga
	}
	return nil
}
