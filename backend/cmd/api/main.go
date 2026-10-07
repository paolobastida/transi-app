package main

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"time"

	"transi/internal/adaptadores/almacen"
	"transi/internal/adaptadores/entradahttp"
	"transi/internal/adaptadores/postgres"
	"transi/internal/adaptadores/seguridad"
	"transi/internal/casosdeuso"
)

func main() {
	slog.SetDefault(slog.New(slog.NewTextHandler(os.Stdout, nil)))
	if err := correr(); err != nil {
		slog.Error("el servidor terminó con error", "error", err)
		os.Exit(1)
	}
}

func correr() error {
	// Base local de desarrollo: sin contraseña y solo accesible desde tu máquina.
	urlBD := env("DATABASE_URL", "postgres://transi@localhost:5432/transi?sslmode=disable")
	puesto := env("PORT", "8080")

	ctx := context.Background()

	bd, err := postgres.NuevaConexion(ctx, urlBD)
	if err != nil {
		return err
	}
	defer bd.Cerrar()
	slog.Info("conectado a la base de datos")

	secreto, generado, err := secretoJWT()
	if err != nil {
		return err
	}
	if generado {
		slog.Warn("JWT_SECRET no definido: uso un secreto aleatorio para esta ejecución (las sesiones no sobreviven un reinicio)")
	}

	const (
		vidaAcceso   = 15 * time.Minute
		vidaRefresco = 30 * 24 * time.Hour
	)
	hasher := seguridad.NuevoHasherBcrypt()
	tokens := seguridad.NuevoTokenizadorJWT(secreto, vidaAcceso)
	identidad := casosdeuso.NuevaIdentidad(
		postgres.NuevoUsuarioRepositorio(bd),
		postgres.NuevoSesionRepositorio(bd),
		hasher,
		tokens,
		vidaRefresco,
	)
	repoProfesionales := postgres.NuevoProfesionalRepositorio(bd)
	profesionales := casosdeuso.NuevoProfesionales(repoProfesionales)
	tratamientos := casosdeuso.NuevoTratamientos(postgres.NuevoTratamientoRepositorio(bd), repoProfesionales)

	// Almacenamiento de archivos: disco local en desarrollo (ADR 005).
	directorioArchivos := env("ARCHIVOS_DIR", "./datos/archivos")
	archivos, err := almacen.NuevoDisco(directorioArchivos)
	if err != nil {
		return err
	}
	slog.Info("archivos en disco", "directorio", directorioArchivos)
	cambios := casosdeuso.NuevosCambios(postgres.NuevoCambioRepositorio(bd), archivos)

	salud := casosdeuso.NuevoVerificarSalud(bd)

	servidor := &http.Server{
		Addr:              ":" + puesto,
		Handler:           entradahttp.NuevoServidor(salud, identidad, profesionales, tratamientos, cambios, tokens).Handler(),
		ReadHeaderTimeout: 5 * time.Second,
	}

	slog.Info("escuchando", "direccion", servidor.Addr)
	if err := servidor.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return err
	}
	return nil
}

func env(clave, porDefecto string) string {
	if valor := os.Getenv(clave); valor != "" {
		return valor
	}
	return porDefecto
}

// secretoJWT usa JWT_SECRET si está definido. Si no, genera uno aleatorio para
// esta ejecución: no queda ningún secreto escrito en el repositorio y las
// sesiones simplemente no sobreviven a un reinicio. En producción DEBE
// definirse JWT_SECRET (estable y secreto).
func secretoJWT() (secreto string, generado bool, err error) {
	if valor := os.Getenv("JWT_SECRET"); valor != "" {
		return valor, false, nil
	}
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", false, err
	}
	return hex.EncodeToString(bytes), true, nil
}
