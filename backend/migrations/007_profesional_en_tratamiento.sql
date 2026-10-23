-- 007_profesional_en_tratamiento: el profesional deja de ser una entidad
-- propia y pasa a ser dos campos opcionales de texto en el tratamiento
-- (nombre + especialidad). Motivo: se registra "quién me atiende" dentro del
-- propio tratamiento, sin gestionar una tabla aparte.
--
-- Los datos existentes se conservan: el nombre y la especialidad se copian
-- desde la tabla profesionales antes de eliminarla.

ALTER TABLE tratamientos
    ADD COLUMN profesional_nombre       TEXT,
    ADD COLUMN profesional_especialidad TEXT;

UPDATE tratamientos t
SET profesional_nombre       = p.nombre,
    profesional_especialidad = p.especialidad
FROM profesionales p
WHERE t.profesional_id = p.id;

ALTER TABLE tratamientos DROP COLUMN profesional_id;

DROP TABLE IF EXISTS profesionales;
