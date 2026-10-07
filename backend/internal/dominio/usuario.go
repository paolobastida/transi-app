// Package dominio contiene el modelo y las reglas de negocio de Transi.
// No conoce HTTP, ni bases de datos, ni frameworks: es el centro del hexágono.
package dominio

import "time"

// Usuario es una cuenta (email + contraseña) dueña de todos los demás datos.
//
// R8: la contraseña se guarda solo como hash irreversible (HashContrasena);
// nunca en claro ni en logs.
type Usuario struct {
	ID             string
	Email          string
	HashContrasena string
	FechaRegistro  time.Time
}
