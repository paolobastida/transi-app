// Package pruebas reúne dobles de prueba (falsos) reutilizables por los tests
// de varios paquetes. No se compila dentro del binario: solo lo usan los tests.
package pruebas

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
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

// GeneradorRefrescoFalso emite refresh tokens deterministas ("refresco-1",
// "refresco-2", …) con su hash para los tests.
type GeneradorRefrescoFalso struct{ contador int }

func (g *GeneradorRefrescoFalso) Generar() (string, string, error) {
	g.contador++
	token := fmt.Sprintf("refresco-%d", g.contador)
	return token, g.Hash(token), nil
}

func (g *GeneradorRefrescoFalso) Hash(token string) string { return "hash:" + token }

// TratamientosFalso es un puertos.TratamientoRepositorio en memoria.
type TratamientosFalso struct {
	PorID map[string]dominio.Tratamiento
}

func NuevoTratamientosFalso() *TratamientosFalso {
	return &TratamientosFalso{PorID: map[string]dominio.Tratamiento{}}
}

func (r *TratamientosFalso) Crear(_ context.Context, t dominio.Tratamiento) error {
	r.PorID[t.ID] = t
	return nil
}

func (r *TratamientosFalso) ListarPorUsuario(_ context.Context, usuarioID string, filtro puertos.FiltroTratamientos) ([]dominio.Tratamiento, error) {
	var resultado []dominio.Tratamiento
	for _, t := range r.PorID {
		if t.UsuarioID != usuarioID || !t.Activo {
			continue
		}
		if filtro.Desde != nil && t.FechaInicio.Before(*filtro.Desde) {
			continue
		}
		if filtro.Hasta != nil && t.FechaInicio.After(*filtro.Hasta) {
			continue
		}
		if filtro.Estado == "activo" && t.Finalizado() {
			continue
		}
		if filtro.Estado == "finalizado" && !t.Finalizado() {
			continue
		}
		resultado = append(resultado, t)
	}
	return resultado, nil
}

func (r *TratamientosFalso) BuscarPorID(_ context.Context, id, usuarioID string) (*dominio.Tratamiento, error) {
	t, ok := r.PorID[id]
	if !ok || t.UsuarioID != usuarioID {
		return nil, puertos.ErrNoEncontrado
	}
	return &t, nil
}

func (r *TratamientosFalso) Actualizar(_ context.Context, t dominio.Tratamiento) error {
	if _, ok := r.PorID[t.ID]; !ok {
		return puertos.ErrNoEncontrado
	}
	r.PorID[t.ID] = t
	return nil
}

func (r *TratamientosFalso) Desactivar(_ context.Context, id, usuarioID string) error {
	t, ok := r.PorID[id]
	if !ok || t.UsuarioID != usuarioID || !t.Activo {
		return puertos.ErrNoEncontrado
	}
	t.Activo = false
	r.PorID[id] = t
	return nil
}

// ArchivosFalso es un puertos.ArchivoAlmacen en memoria.
type ArchivosFalso struct {
	PorReferencia map[string][]byte
	Borrados      []string
	FallaAlSubir  bool
	contador      int
}

func NuevoArchivosFalso() *ArchivosFalso {
	return &ArchivosFalso{PorReferencia: map[string][]byte{}}
}

func (a *ArchivosFalso) Subir(_ context.Context, nombre string, contenido io.Reader) (string, error) {
	if a.FallaAlSubir {
		return "", errors.New("falla de almacenamiento")
	}
	datos, err := io.ReadAll(contenido)
	if err != nil {
		return "", err
	}
	a.contador++
	referencia := fmt.Sprintf("ref-%d-%s", a.contador, nombre)
	a.PorReferencia[referencia] = datos
	return referencia, nil
}

func (a *ArchivosFalso) Bajar(_ context.Context, referencia string) (io.ReadCloser, error) {
	datos, ok := a.PorReferencia[referencia]
	if !ok {
		return nil, puertos.ErrNoEncontrado
	}
	return io.NopCloser(bytes.NewReader(datos)), nil
}

func (a *ArchivosFalso) Borrar(_ context.Context, referencia string) error {
	delete(a.PorReferencia, referencia)
	a.Borrados = append(a.Borrados, referencia)
	return nil
}

// CambiosFalso es un puertos.CambioRepositorio en memoria.
type CambiosFalso struct {
	PorID        map[string]dominio.Cambio
	FallaAlCrear bool
}

func NuevoCambiosFalso() *CambiosFalso {
	return &CambiosFalso{PorID: map[string]dominio.Cambio{}}
}

func (r *CambiosFalso) Crear(_ context.Context, c dominio.Cambio) error {
	if r.FallaAlCrear {
		return errors.New("falla al guardar la ficha")
	}
	r.PorID[c.ID] = c
	return nil
}

func (r *CambiosFalso) ListarPorUsuario(_ context.Context, usuarioID string, filtro puertos.FiltroCambios) ([]dominio.Cambio, error) {
	var resultado []dominio.Cambio
	for _, c := range r.PorID {
		if c.UsuarioID != usuarioID || !c.Activo {
			continue
		}
		if filtro.Desde != nil && c.Fecha.Before(*filtro.Desde) {
			continue
		}
		if filtro.Hasta != nil && c.Fecha.After(*filtro.Hasta) {
			continue
		}
		resultado = append(resultado, c)
	}
	return resultado, nil
}

func (r *CambiosFalso) BuscarPorID(_ context.Context, id, usuarioID string) (*dominio.Cambio, error) {
	c, ok := r.PorID[id]
	if !ok || c.UsuarioID != usuarioID {
		return nil, puertos.ErrNoEncontrado
	}
	return &c, nil
}

func (r *CambiosFalso) Actualizar(_ context.Context, c dominio.Cambio) error {
	if _, ok := r.PorID[c.ID]; !ok {
		return puertos.ErrNoEncontrado
	}
	r.PorID[c.ID] = c
	return nil
}

func (r *CambiosFalso) Desactivar(_ context.Context, id, usuarioID string) error {
	c, ok := r.PorID[id]
	if !ok || c.UsuarioID != usuarioID || !c.Activo {
		return puertos.ErrNoEncontrado
	}
	c.Activo = false
	r.PorID[id] = c
	return nil
}

// RespaldosFalso es un puertos.RespaldoRepositorio en memoria.
type RespaldosFalso struct {
	PorUsuario   map[string][]dominio.Respaldo
	FallaAlCrear bool
}

func NuevoRespaldosFalso() *RespaldosFalso {
	return &RespaldosFalso{PorUsuario: map[string][]dominio.Respaldo{}}
}

func (r *RespaldosFalso) Crear(_ context.Context, respaldo dominio.Respaldo) error {
	if r.FallaAlCrear {
		return errors.New("falla al guardar el respaldo")
	}
	r.PorUsuario[respaldo.UsuarioID] = append(r.PorUsuario[respaldo.UsuarioID], respaldo)
	return nil
}

func (r *RespaldosFalso) Ultimo(_ context.Context, usuarioID string) (*dominio.Respaldo, error) {
	respaldos := r.PorUsuario[usuarioID]
	if len(respaldos) == 0 {
		return nil, puertos.ErrNoEncontrado
	}
	ultimo := respaldos[0]
	for _, respaldo := range respaldos {
		if respaldo.CreadoEn.After(ultimo.CreadoEn) {
			ultimo = respaldo
		}
	}
	return &ultimo, nil
}

func (r *RespaldosFalso) ListarPorUsuario(_ context.Context, usuarioID string) ([]dominio.Respaldo, error) {
	return r.PorUsuario[usuarioID], nil
}
