package seguridad

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
)

// GeneradorRefrescoAleatorio implementa puertos.GeneradorRefresco con un token
// opaco de 32 bytes aleatorios y su SHA-256. No es criptografía propia: usa los
// primitivos de la biblioteca estándar.
type GeneradorRefrescoAleatorio struct{}

func NuevoGeneradorRefresco() GeneradorRefrescoAleatorio {
	return GeneradorRefrescoAleatorio{}
}

func (GeneradorRefrescoAleatorio) Generar() (token, hash string, err error) {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", "", err
	}
	token = base64.RawURLEncoding.EncodeToString(bytes)
	return token, HashDeToken(token), nil
}

func (GeneradorRefrescoAleatorio) Hash(token string) string {
	return HashDeToken(token)
}

// HashDeToken hashea un refresh token para guardarlo o buscarlo. Así el token
// en claro nunca toca la base.
func HashDeToken(token string) string {
	suma := sha256.Sum256([]byte(token))
	return hex.EncodeToString(suma[:])
}
