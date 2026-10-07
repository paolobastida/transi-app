package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"time"

	"transi/internal/adaptadores/entradahttp"
	"transi/internal/adaptadores/postgres"
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
	urlBD := env("DATABASE_URL", "postgres://transi@localhost:5432/transi?sslmode=disable")
	puesto := env("PORT", "8080")

	ctx := context.Background()

	bd, err := postgres.NuevaConexion(ctx, urlBD)
	if err != nil {
		return err
	}
	defer bd.Cerrar()
	slog.Info("conectado a la base de datos")

	salud := casosdeuso.NuevoVerificarSalud(bd)
	servidor := &http.Server{
		Addr:              ":" + puesto,
		Handler:           entradahttp.NuevoServidor(salud).Handler(),
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
