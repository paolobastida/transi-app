package dominio

import "time"

// Respaldo es una "foto" completa de los datos de un usuario, guardada como
// archivo. El servidor no interpreta su contenido: solo lo almacena y lo
// devuelve para restaurar (U16).
type Respaldo struct {
	ID        string
	UsuarioID string
	Archivo   string
	CreadoEn  time.Time
}
