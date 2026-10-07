// Package casosdeuso orquesta el dominio y los puertos para resolver las
// acciones del usuario (U1–U16 de architecture.md). No conoce adaptadores.
package casosdeuso

import (
	"context"

	"transi/internal/puertos"
)

// VerificarSalud comprueba que el servidor y sus dependencias están vivos.
type VerificarSalud struct {
	verificador puertos.VerificadorSalud
}

func NuevoVerificarSalud(v puertos.VerificadorSalud) VerificarSalud {
	return VerificarSalud{verificador: v}
}

// Ejecutar devuelve nil si la dependencia responde; si no, el error original.
func (c VerificarSalud) Ejecutar(ctx context.Context) error {
	return c.verificador.Ping(ctx)
}
