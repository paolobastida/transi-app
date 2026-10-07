package dominio

import "time"

// Sesion es el refresh token guardado en el servidor (ADR 004).
// Es la parte revocable: borrar la fila cierra la sesión.
//
// Por seguridad no se guarda el token en claro, solo su hash (HashToken).
type Sesion struct {
	ID        string
	UsuarioID string
	HashToken string
	ExpiraEn  time.Time
	CreadoEn  time.Time
}
