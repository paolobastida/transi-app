-- 005_respaldos: historial de respaldos por usuario (U16).
-- El contenido del respaldo vive en el ArchivoAlmacen; acá solo la referencia.

CREATE TABLE respaldos (
    id         UUID PRIMARY KEY,
    usuario_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    archivo    TEXT NOT NULL,
    creado_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_respaldos_usuario ON respaldos (usuario_id, creado_en DESC);
