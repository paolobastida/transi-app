package seguridad

import (
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"transi/internal/puertos"
)

// ErrTokenInvalido indica que el access token no se pudo validar.
var ErrTokenInvalido = errors.New("token inválido")

// TokenizadorJWT implementa puertos.Tokenizador con JWT HS256 (ADR 004).
type TokenizadorJWT struct {
	secreto []byte
	vida    time.Duration
}

func NuevoTokenizadorJWT(secreto string, vida time.Duration) *TokenizadorJWT {
	return &TokenizadorJWT{secreto: []byte(secreto), vida: vida}
}

func (t *TokenizadorJWT) GenerarAcceso(usuarioID, email string) (string, time.Time, error) {
	ahora := time.Now().UTC()
	expiraEn := ahora.Add(t.vida)
	claims := jwt.MapClaims{
		"sub":   usuarioID,
		"email": email,
		"iat":   ahora.Unix(),
		"exp":   expiraEn.Unix(),
	}
	firmado, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(t.secreto)
	if err != nil {
		return "", time.Time{}, err
	}
	return firmado, expiraEn, nil
}

func (t *TokenizadorJWT) ValidarAcceso(token string) (puertos.UsuarioAutenticado, error) {
	parseado, err := jwt.Parse(token, func(tk *jwt.Token) (any, error) {
		if _, ok := tk.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("método de firma inesperado: %v", tk.Header["alg"])
		}
		return t.secreto, nil
	}, jwt.WithValidMethods([]string{"HS256"}))
	if err != nil || !parseado.Valid {
		return puertos.UsuarioAutenticado{}, ErrTokenInvalido
	}

	claims, ok := parseado.Claims.(jwt.MapClaims)
	if !ok {
		return puertos.UsuarioAutenticado{}, ErrTokenInvalido
	}
	id, _ := claims["sub"].(string)
	email, _ := claims["email"].(string)
	if id == "" {
		return puertos.UsuarioAutenticado{}, ErrTokenInvalido
	}
	return puertos.UsuarioAutenticado{ID: id, Email: email}, nil
}
