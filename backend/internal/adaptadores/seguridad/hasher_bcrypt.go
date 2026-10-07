// Package seguridad implementa los puertos de hash de contraseñas y de
// emisión/validación de tokens usando librerías estándar y maduras.
package seguridad

import "golang.org/x/crypto/bcrypt"

// HasherBcrypt implementa puertos.Hasher con bcrypt (R8: hash irreversible).
type HasherBcrypt struct {
	costo int
}

func NuevoHasherBcrypt() *HasherBcrypt {
	return &HasherBcrypt{costo: bcrypt.DefaultCost}
}

func (h *HasherBcrypt) Hashear(clave string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(clave), h.costo)
	if err != nil {
		return "", err
	}
	return string(hash), nil
}

func (h *HasherBcrypt) Verificar(hash, clave string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(clave)) == nil
}
