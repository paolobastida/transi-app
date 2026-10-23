package main

import (
	"crypto/rand"
	"encoding/hex"
	"log/slog"
	"os"
	"strings"
	"time"
)

// configuracion reúne todo lo que el proceso lee del entorno.
//
// Separar la *lectura* de la configuración del *armado* del servidor es el
// principio de responsabilidad única aplicado al arranque: este archivo decide
// con qué valores corre el proceso; `main.go` decide cómo se conectan las piezas.
type configuracion struct {
	urlBaseDatos    string
	puerto          string
	secretoJWT      string
	directorioDatos string
	proxies         []string
	origenesCORS    []string

	vidaAcceso    time.Duration
	vidaRefresco  time.Duration
	maxIntentos   int
	periodoLimite time.Duration
}

// leerConfiguracion arma la configuración desde las variables de entorno,
// aplicando valores por defecto seguros y avisando cuando falta algo.
func leerConfiguracion() (configuracion, error) {
	secreto, generado, err := secretoJWT()
	if err != nil {
		return configuracion{}, err
	}
	if generado {
		slog.Warn("JWT_SECRET no definido: uso un secreto aleatorio para esta ejecución (las sesiones no sobreviven un reinicio)")
	}

	origenes, err := origenesCORS()
	if err != nil {
		return configuracion{}, err
	}

	// Solo nos creemos X-Forwarded-For si la conexión viene de un proxy de
	// confianza (el reverse proxy que publica la API). Sin esto, cualquiera
	// podría falsear la cabecera y saltarse el límite de intentos.
	proxies := separar(env("PROXIES_CONFIABLES", ""))
	if len(proxies) > 0 {
		slog.Info("proxies de confianza para X-Forwarded-For", "proxies", proxies)
	}

	return configuracion{
		urlBaseDatos:    env("DATABASE_URL", "postgres://transi@localhost:5432/transi?sslmode=disable"),
		puerto:          env("PORT", "8080"),
		secretoJWT:      secreto,
		directorioDatos: env("ARCHIVOS_DIR", "./datos/archivos"),
		proxies:         proxies,
		origenesCORS:    origenes,

		vidaAcceso:    15 * time.Minute,
		vidaRefresco:  30 * 24 * time.Hour,
		maxIntentos:   10,
		periodoLimite: time.Minute,
	}, nil
}

func env(clave, porDefecto string) string {
	if valor := os.Getenv(clave); valor != "" {
		return valor
	}
	return porDefecto
}

// separar divide una lista separada por comas, ignorando espacios vacíos.
func separar(valor string) []string {
	var partes []string
	for _, parte := range strings.Split(valor, ",") {
		if recortada := strings.TrimSpace(parte); recortada != "" {
			partes = append(partes, recortada)
		}
	}
	return partes
}

// origenesCORS decide qué orígenes puede llamar a la API.
//
// Es **fail-closed** a propósito: si CORS_ORIGENES no está definida, el
// servidor arranca sin permitir orígenes cruzados (la app móvil no depende de
// CORS, solo la versión web). Antes el valor por omisión era "*", y además
// `CORS_ORIGENES=` vacío se invertía silenciosamente a comodín.
func origenesCORS() ([]string, error) {
	valor, definida := os.LookupEnv("CORS_ORIGENES")
	if !definida || strings.TrimSpace(valor) == "" {
		slog.Info("CORS_ORIGENES no definida: no se permiten orígenes cruzados " +
			"(normal en la app móvil; definela para usar la versión web)")
		return nil, nil
	}
	origenes := separar(valor)
	if len(origenes) == 1 && origenes[0] == "*" {
		slog.Warn("CORS_ORIGENES=\"*\": cualquier sitio puede llamar a la API. " +
			"Usalo solo en desarrollo.")
	}
	return origenes, nil
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
