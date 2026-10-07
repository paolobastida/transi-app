package casosdeuso

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"time"

	"github.com/google/uuid"

	"transi/internal/dominio"
	"transi/internal/puertos"
)

// Errores de identidad que los adaptadores traducen a respuestas HTTP.
var (
	// ErrCredencialesInvalidas: email o contraseña incorrectos (no revelamos cuál).
	ErrCredencialesInvalidas = errors.New("email o contraseña incorrectos")
	// ErrNoAutenticado: no hay sesión válida.
	ErrNoAutenticado = errors.New("sesión no válida")
)

// Tokens es el par que se entrega al iniciar o renovar una sesión.
type Tokens struct {
	Acceso         string
	Refresco       string
	AccesoExpiraEn time.Time
}

// Credenciales es lo que llega en registro y login.
type Credenciales struct {
	Email string
	Clave string
}

// Identidad agrupa los casos de uso U1–U3 (ADR 004).
type Identidad struct {
	usuarios     puertos.UsuarioRepositorio
	sesiones     puertos.SesionRepositorio
	hasher       puertos.Hasher
	tokens       puertos.Tokenizador
	vidaRefresco time.Duration
}

func NuevaIdentidad(
	usuarios puertos.UsuarioRepositorio,
	sesiones puertos.SesionRepositorio,
	hasher puertos.Hasher,
	tokens puertos.Tokenizador,
	vidaRefresco time.Duration,
) Identidad {
	return Identidad{
		usuarios:     usuarios,
		sesiones:     sesiones,
		hasher:       hasher,
		tokens:       tokens,
		vidaRefresco: vidaRefresco,
	}
}

// U1 · Registrarse. Email único; contraseña ≥ 8; solo se guarda el hash (R8).
func (i Identidad) Registrarse(ctx context.Context, c Credenciales) (dominio.Usuario, error) {
	if err := dominio.ValidarEmail(c.Email); err != nil {
		return dominio.Usuario{}, err
	}
	if err := dominio.ValidarContrasena(c.Clave); err != nil {
		return dominio.Usuario{}, err
	}
	if _, err := i.usuarios.BuscarPorEmail(ctx, c.Email); err == nil {
		return dominio.Usuario{}, puertos.ErrConflicto
	} else if !errors.Is(err, puertos.ErrNoEncontrado) {
		return dominio.Usuario{}, err
	}

	hash, err := i.hasher.Hashear(c.Clave)
	if err != nil {
		return dominio.Usuario{}, err
	}
	u := dominio.Usuario{
		ID:             uuid.NewString(),
		Email:          c.Email,
		HashContrasena: hash,
		FechaRegistro:  time.Now().UTC(),
	}
	if err := i.usuarios.Crear(ctx, u); err != nil {
		return dominio.Usuario{}, err
	}
	return u, nil
}

// U2 · Iniciar sesión. Requiere red; verifica la contraseña y abre sesión.
func (i Identidad) IniciarSesion(ctx context.Context, c Credenciales) (Tokens, error) {
	u, err := i.usuarios.BuscarPorEmail(ctx, c.Email)
	if errors.Is(err, puertos.ErrNoEncontrado) {
		return Tokens{}, ErrCredencialesInvalidas
	}
	if err != nil {
		return Tokens{}, err
	}
	if !i.hasher.Verificar(u.HashContrasena, c.Clave) {
		return Tokens{}, ErrCredencialesInvalidas
	}
	return i.emitir(ctx, *u)
}

// Renovar rota el refresh token: el viejo se invalida y se emite uno nuevo.
func (i Identidad) Renovar(ctx context.Context, refresco string) (Tokens, error) {
	sesion, err := i.sesiones.BuscarPorHash(ctx, hashDeToken(refresco))
	if errors.Is(err, puertos.ErrNoEncontrado) {
		return Tokens{}, ErrNoAutenticado
	}
	if err != nil {
		return Tokens{}, err
	}
	if time.Now().UTC().After(sesion.ExpiraEn) {
		_ = i.sesiones.Borrar(ctx, sesion.HashToken)
		return Tokens{}, ErrNoAutenticado
	}

	u, err := i.usuarios.BuscarPorID(ctx, sesion.UsuarioID)
	if errors.Is(err, puertos.ErrNoEncontrado) {
		return Tokens{}, ErrNoAutenticado
	}
	if err != nil {
		return Tokens{}, err
	}

	// Emitir el nuevo par antes de invalidar el viejo.
	nuevos, err := i.emitir(ctx, *u)
	if err != nil {
		return Tokens{}, err
	}
	_ = i.sesiones.Borrar(ctx, sesion.HashToken)
	return nuevos, nil
}

// CerrarSesion revoca el refresh token (borrar la fila cierra la sesión).
func (i Identidad) CerrarSesion(ctx context.Context, refresco string) error {
	err := i.sesiones.Borrar(ctx, hashDeToken(refresco))
	if errors.Is(err, puertos.ErrNoEncontrado) {
		return nil
	}
	return err
}

// U3 · Obtener quién soy. Verifica que la cuenta siga existiendo.
func (i Identidad) QuienSoy(ctx context.Context, actual puertos.UsuarioAutenticado) (dominio.Usuario, error) {
	u, err := i.usuarios.BuscarPorID(ctx, actual.ID)
	if errors.Is(err, puertos.ErrNoEncontrado) {
		return dominio.Usuario{}, ErrNoAutenticado
	}
	if err != nil {
		return dominio.Usuario{}, err
	}
	return *u, nil
}

// emitir genera el access JWT y un refresh token nuevo, y guarda la sesión.
func (i Identidad) emitir(ctx context.Context, u dominio.Usuario) (Tokens, error) {
	acceso, expiraEn, err := i.tokens.GenerarAcceso(u.ID, u.Email)
	if err != nil {
		return Tokens{}, err
	}
	refresco, hash, err := generarTokenRefresco()
	if err != nil {
		return Tokens{}, err
	}
	ahora := time.Now().UTC()
	err = i.sesiones.Guardar(ctx, dominio.Sesion{
		ID:        uuid.NewString(),
		UsuarioID: u.ID,
		HashToken: hash,
		ExpiraEn:  ahora.Add(i.vidaRefresco),
		CreadoEn:  ahora,
	})
	if err != nil {
		return Tokens{}, err
	}
	return Tokens{Acceso: acceso, Refresco: refresco, AccesoExpiraEn: expiraEn}, nil
}

// generarTokenRefresco devuelve el token en claro (va al celular) y su hash
// (queda en la base). Son aleatorios con crypto/rand: no es criptografía propia.
func generarTokenRefresco() (token, hash string, err error) {
	bytes := make([]byte, 32)
	if _, err = rand.Read(bytes); err != nil {
		return "", "", err
	}
	token = base64.RawURLEncoding.EncodeToString(bytes)
	return token, hashDeToken(token), nil
}

func hashDeToken(token string) string {
	suma := sha256.Sum256([]byte(token))
	return hex.EncodeToString(suma[:])
}
