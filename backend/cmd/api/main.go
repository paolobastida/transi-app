package main

import (
	"context"
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

// correr arma el servidor con las piezas concretas que elige la configuración.
// Solo *conecta*: leer el entorno es responsabilidad de leerConfiguracion.
func correr() error {
	cfg, err := leerConfiguracion()
	if err != nil {
		return err
	}

	ctx := context.Background()

	bd, err := postgres.NuevaConexion(ctx, cfg.urlBaseDatos)
	if err != nil {
		return err
	}
	defer bd.Cerrar()
	slog.Info("conectado a la base de datos")

	hasher := seguridad.NuevoHasherBcrypt()
	tokens := seguridad.NuevoTokenizadorJWT(cfg.secretoJWT, cfg.vidaAcceso)
	identidad := casosdeuso.NuevaIdentidad(
		postgres.NuevoUsuarioRepositorio(bd),
		postgres.NuevoSesionRepositorio(bd),
		hasher,
		tokens,
		seguridad.NuevoGeneradorRefresco(),
		cfg.vidaRefresco,
	)
	tratamientos := casosdeuso.NuevoTratamientos(postgres.NuevoTratamientoRepositorio(bd))

	// Almacenamiento de archivos: disco local en desarrollo (ADR 005).
	archivos, err := almacen.NuevoDisco(cfg.directorioDatos)
	if err != nil {
		return err
	}
	slog.Info("archivos en disco", "directorio", cfg.directorioDatos)
	cambios := casosdeuso.NuevosCambios(postgres.NuevoCambioRepositorio(bd), archivos)
	respaldos := casosdeuso.NuevosRespaldos(postgres.NuevoRespaldoRepositorio(bd), archivos)

	salud := casosdeuso.NuevoVerificarSalud(bd)

	// Límite de intentos por IP en /auth/*: frena fuerza bruta y el DoS de CPU
	// (cada intento de login ejecuta un bcrypt).
	limites := entradahttp.NuevoLimitador(cfg.maxIntentos, cfg.periodoLimite, cfg.proxies)
	go func() {
		for range time.Tick(cfg.periodoLimite) {
			limites.Limpiar()
		}
	}()

	servidor := &http.Server{
		Addr: ":" + cfg.puerto,
		Handler: entradahttp.ConCORS(cfg.origenesCORS,
			entradahttp.NuevoServidor(salud, identidad, tratamientos, cambios, respaldos, tokens, limites).Handler()),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      2 * time.Minute,
		IdleTimeout:       60 * time.Second,
		MaxHeaderBytes:    1 << 16,
	}

	slog.Info("escuchando", "direccion", servidor.Addr)
	if err := servidor.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return err
	}
	return nil
}
