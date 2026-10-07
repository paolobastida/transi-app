-- 003_profesionales_tratamientos: contextos Tratamientos y Profesionales.
-- R5: se usa borrado lógico (columna activo); nunca se borra una fila con historial.
-- El estado "activo/finalizado" de un tratamiento NO se guarda: se deriva de fecha_fin.

CREATE TABLE profesionales (
    id           UUID PRIMARY KEY,
    usuario_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    nombre       TEXT NOT NULL,
    especialidad TEXT NOT NULL,
    activo       BOOLEAN NOT NULL DEFAULT true,
    creado_en    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_profesionales_usuario ON profesionales (usuario_id);

CREATE TABLE tratamientos (
    id             UUID PRIMARY KEY,
    usuario_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    nombre         TEXT NOT NULL,
    dosis          TEXT NOT NULL,
    frecuencia     TEXT NOT NULL,
    fecha_inicio   DATE NOT NULL,
    fecha_fin      DATE,
    profesional_id UUID REFERENCES profesionales(id),
    activo         BOOLEAN NOT NULL DEFAULT true,
    creado_en      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_tratamientos_usuario ON tratamientos (usuario_id);
