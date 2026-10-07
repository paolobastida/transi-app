package casosdeuso

import (
	"context"
	"errors"
	"testing"
	"time"

	"transi/internal/dominio"
	"transi/internal/pruebas"
	"transi/internal/puertos"
)

func identidadDePrueba() (Identidad, *pruebas.UsuariosFalso, *pruebas.SesionesFalso) {
	usuarios := pruebas.NuevoUsuariosFalso()
	sesiones := pruebas.NuevoSesionesFalso()
	id := NuevaIdentidad(usuarios, sesiones, pruebas.HasherFalso{}, pruebas.TokenizadorFalso{}, 30*24*time.Hour)
	return id, usuarios, sesiones
}

func TestRegistrarse(t *testing.T) {
	id, _, _ := identidadDePrueba()
	u, err := id.Registrarse(context.Background(), Credenciales{Email: "tina@transi.test", Clave: "secreto123"})
	if err != nil {
		t.Fatalf("registro: %v", err)
	}
	if u.ID == "" {
		t.Fatal("esperaba un id generado")
	}
	if u.HashContrasena == "secreto123" {
		t.Fatal("la contraseña no debe guardarse en claro (R8)")
	}
}

func TestRegistrarseEmailDuplicado(t *testing.T) {
	id, _, _ := identidadDePrueba()
	ctx := context.Background()
	if _, err := id.Registrarse(ctx, Credenciales{Email: "tina@transi.test", Clave: "secreto123"}); err != nil {
		t.Fatalf("primer registro: %v", err)
	}
	_, err := id.Registrarse(ctx, Credenciales{Email: "tina@transi.test", Clave: "otraclave1"})
	if !errors.Is(err, puertos.ErrConflicto) {
		t.Fatalf("esperaba ErrConflicto, obtuve %v", err)
	}
}

func TestRegistrarseValidaciones(t *testing.T) {
	id, _, _ := identidadDePrueba()
	ctx := context.Background()
	if _, err := id.Registrarse(ctx, Credenciales{Email: "no-es-email", Clave: "secreto123"}); !errors.Is(err, dominio.ErrEmailInvalido) {
		t.Fatalf("esperaba ErrEmailInvalido, obtuve %v", err)
	}
	if _, err := id.Registrarse(ctx, Credenciales{Email: "tina@transi.test", Clave: "corta"}); !errors.Is(err, dominio.ErrContrasenaCorta) {
		t.Fatalf("esperaba ErrContrasenaCorta, obtuve %v", err)
	}
}

func TestLoginBuenoYMalos(t *testing.T) {
	id, _, _ := identidadDePrueba()
	ctx := context.Background()
	if _, err := id.Registrarse(ctx, Credenciales{Email: "tina@transi.test", Clave: "secreto123"}); err != nil {
		t.Fatalf("registro: %v", err)
	}

	tokens, err := id.IniciarSesion(ctx, Credenciales{Email: "tina@transi.test", Clave: "secreto123"})
	if err != nil {
		t.Fatalf("login: %v", err)
	}
	if tokens.Acceso == "" || tokens.Refresco == "" {
		t.Fatal("esperaba access y refresh")
	}

	if _, err := id.IniciarSesion(ctx, Credenciales{Email: "tina@transi.test", Clave: "malamala"}); !errors.Is(err, ErrCredencialesInvalidas) {
		t.Fatalf("esperaba ErrCredencialesInvalidas, obtuve %v", err)
	}
	if _, err := id.IniciarSesion(ctx, Credenciales{Email: "nadie@transi.test", Clave: "secreto123"}); !errors.Is(err, ErrCredencialesInvalidas) {
		t.Fatalf("esperaba ErrCredencialesInvalidas, obtuve %v", err)
	}
}

func TestRenovarRotaElRefresco(t *testing.T) {
	id, _, _ := identidadDePrueba()
	ctx := context.Background()
	_, _ = id.Registrarse(ctx, Credenciales{Email: "tina@transi.test", Clave: "secreto123"})
	tokens, _ := id.IniciarSesion(ctx, Credenciales{Email: "tina@transi.test", Clave: "secreto123"})

	nuevos, err := id.Renovar(ctx, tokens.Refresco)
	if err != nil {
		t.Fatalf("renovar: %v", err)
	}
	if nuevos.Refresco == tokens.Refresco {
		t.Fatal("el refresh debía rotar")
	}
	if _, err := id.Renovar(ctx, tokens.Refresco); !errors.Is(err, ErrNoAutenticado) {
		t.Fatalf("el refresh viejo debía quedar inválido, obtuve %v", err)
	}
}

func TestCerrarSesionInvalidaElRefresco(t *testing.T) {
	id, _, _ := identidadDePrueba()
	ctx := context.Background()
	_, _ = id.Registrarse(ctx, Credenciales{Email: "tina@transi.test", Clave: "secreto123"})
	tokens, _ := id.IniciarSesion(ctx, Credenciales{Email: "tina@transi.test", Clave: "secreto123"})

	if err := id.CerrarSesion(ctx, tokens.Refresco); err != nil {
		t.Fatalf("logout: %v", err)
	}
	if _, err := id.Renovar(ctx, tokens.Refresco); !errors.Is(err, ErrNoAutenticado) {
		t.Fatalf("tras logout el refresh no debía servir, obtuve %v", err)
	}
}

func TestQuienSoy(t *testing.T) {
	id, _, _ := identidadDePrueba()
	ctx := context.Background()
	u, _ := id.Registrarse(ctx, Credenciales{Email: "tina@transi.test", Clave: "secreto123"})

	actual, err := id.QuienSoy(ctx, puertos.UsuarioAutenticado{ID: u.ID})
	if err != nil {
		t.Fatalf("quién soy: %v", err)
	}
	if actual.Email != "tina@transi.test" {
		t.Fatalf("email = %q", actual.Email)
	}
}
