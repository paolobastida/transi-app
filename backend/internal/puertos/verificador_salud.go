package puertos

import "context"

// VerificadorSalud comprueba que una dependencia externa (por ejemplo la base
// de datos) responde. Es un puerto: el caso de uso VerificarSalud no sabe si
// detrás hay Postgres, memoria o un falso.
type VerificadorSalud interface {
	Ping(ctx context.Context) error
}
