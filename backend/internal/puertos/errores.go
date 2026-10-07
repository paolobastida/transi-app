// Package puertos define los contratos (interfaces) que el núcleo de Transi
// necesita. Dicen *qué* se necesita, sin mencionar tecnología alguna; los
// adaptadores son quienes los cumplen.
package puertos

import "errors"

var (
	// ErrNoEncontrado indica que el recurso pedido no existe.
	ErrNoEncontrado = errors.New("no encontrado")
	// ErrConflicto indica que una operación choca con el estado actual
	// (por ejemplo, un email ya registrado).
	ErrConflicto = errors.New("conflicto")
)
