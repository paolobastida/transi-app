-- 006_tratamientos_campos_clinicos: campos opcionales que hacen al
-- tratamiento clínicamente interpretable. Todos son nullable para no romper
-- los tratamientos ya guardados (compatibilidad hacia atrás).
--
-- via            → vía de administración (oral, inyectable, transdérmico…).
--                 Sin ella, "2 mg" es ambiguo: oral, sublingual e inyección
--                 de 2 mg son regímenes distintos.
-- presentacion   → sal/concentración (ej. "cipionato 200 mg/mL"), que
--                 determina la vida media y por ende la frecuencia.
-- dosis_cantidad → cantidad numérica de la dosis (estructura dosis).
-- dosis_unidad   → unidad de la dosis (mg, mcg, mL, tableta…).
-- indicacion     → propósito clínico (feminización, masculinización…).

ALTER TABLE tratamientos
    ADD COLUMN via            TEXT,
    ADD COLUMN presentacion   TEXT,
    ADD COLUMN dosis_cantidad DOUBLE PRECISION,
    ADD COLUMN dosis_unidad   TEXT,
    ADD COLUMN indicacion     TEXT;
