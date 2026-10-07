// Package pruebas reúne dobles de prueba (falsos) reutilizables por los tests
// de varios paquetes. No se compila dentro del binario: solo lo usan los tests.
package pruebas

import (
	"context"
	"errors"
	"strings"
	"time"

	"transi/internal/dominio"
	"transi/internal/puertos"
)

// UsuariosFalso es un puertos.UsuarioRepositorio en memoria.
type UsuariosFalso struct {
	PorEmail map[string]dominio.Usuario
	PorID    map[string]dominio.Usuario
}

func NuevoUsuariosFalso() *UsuariosFalso {
	return &UsuariosFalso{
		PorEmail: map[string]dominio.Usuario{},
		PorID:    map[string]dominio.Usuario{},
	}
}

func (r *UsuariosFalso) Crear(_ context.Context, u dominio.Usuario) error {
	if _, existe := r.PorEmail[u.Email]; existe {
		return puertos.ErrConflicto
	}
	r.PorEmail[u.Email] = u
	r.PorID[u.ID] = u
	return nil
}

func (r *UsuariosFalso) BuscarPorEmail(_ context.Context, email string) (*dominio.Usuario, error) {
	u, ok := r.PorEmail[email]
	if !ok {
		return nil, puertos.ErrNoEncontrado
	}
	return &u, nil
}

func (r *UsuariosFalso) BuscarPorID(_ context.Context, id string) (*dominio.Usuario, error) {
	u, ok := r.PorID[id]
	if !ok {
		return nil, puertos.ErrNoEncontrado
	}
	return &u, nil
}

// SesionesFalso es un puertos.SesionRepositorio en memoria.
type SesionesFalso struct {
	PorHash map[string]dominio.Sesion
}

func NuevoSesionesFalso() *SesionesFalso {
	return &SesionesFalso{PorHash: map[string]dominio.Sesion{}}
}

func (r *SesionesFalso) Guardar(_ context.Context, s dominio.Sesion) error {
	r.PorHash[s.HashToken] = s
	return nil
}

func (r *SesionesFalso) BuscarPorHash(_ context.Context, hash string) (*dominio.Sesion, error) {
	s, ok := r.PorHash[hash]
	if !ok {
		return nil, puertos.ErrNoEncontrado
	}
	return &s, nil
}

func (r *SesionesFalso) Borrar(_ context.Context, hash string) error {
	if _, ok := r.PorHash[hash]; !ok {
		return puertos.ErrNoEncontrado
	}
	delete(r.PorHash, hash)
	return nil
}

// HasherFalso marca las claves de forma reversible, solo para tests.
type HasherFalso struct{}

func (HasherFalso) Hashear(clave string) (string, error) { return "hash:" + clave, nil }
func (HasherFalso) Verificar(hash, clave string) bool    { return hash == "hash:"+clave }

// TokenizadorFalso emite tokens con la forma "acceso:<id>:<email>".
type TokenizadorFalso struct{}

func (TokenizadorFalso) GenerarAcceso(id, email string) (string, time.Time, error) {
	return "acceso:" + id + ":" + email, time.Now().Add(15 * time.Minute), nil
}

func (TokenizadorFalso) ValidarAcceso(token string) (puertos.UsuarioAutenticado, error) {
	partes := strings.Split(token, ":")
	if len(partes) != 3 || partes[0] != "acceso" {
		return puertos.UsuarioAutenticado{}, errors.New("token inválido")
	}
	return puertos.UsuarioAutenticado{ID: partes[1], Email: partes[2]}, nil
}
