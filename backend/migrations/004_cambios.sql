-- 004_cambios: contexto Cambios (hecho físico + adjuntos).
-- El contenido de los archivos NO vive acá: solo su referencia (ADR 005).
-- R5: borrado lógico (columna activo).

CREATE TABLE cambios (
    id          UUID PRIMARY KEY,
    usuario_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fecha       DATE NOT NULL,
    descripcion TEXT NOT NULL DEFAULT '',
    activo      BOOLEAN NOT NULL DEFAULT true,
    creado_en   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_cambios_usuario ON cambios (usuario_id);

CREATE TABLE adjuntos (
    id        UUID PRIMARY KEY,
    cambio_id UUID NOT NULL REFERENCES cambios(id) ON DELETE CASCADE,
    tipo      TEXT NOT NULL CHECK (tipo IN ('foto', 'audio')),
    archivo   TEXT NOT NULL,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_adjuntos_cambio ON adjuntos (cambio_id);
