package puertos

import "time"

// Hasher convierte una contraseña en un hash irreversible y la verifica.
// R8: la contraseña nunca se guarda en claro.
type Hasher interface {
	Hashear(clave string) (string, error)
	Verificar(hash, clave string) bool
}

// UsuarioAutenticado es lo que un access token válido declara.
type UsuarioAutenticado struct {
	ID    string
	Email string
}

// Tokenizador emite y valida el access token (JWT) de ADR 004.
type Tokenizador interface {
	// GenerarAcceso devuelve el token firmado y el momento en que vence.
	GenerarAcceso(usuarioID, email string) (token string, expiraEn time.Time, err error)
	// ValidarAcceso devuelve el usuario o un error si el token no sirve.
	ValidarAcceso(token string) (UsuarioAutenticado, error)
}
