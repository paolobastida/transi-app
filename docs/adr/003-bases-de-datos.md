# ADR 003 — Bases de datos: PostgreSQL (servidor) + Drift/SQLite (celular)

**Fecha:** 2026-10-06 · **Estado:** Aceptado

## Contexto

- **Servidor:** guardar cuentas y respaldos bajo demanda. El modelo de
  `domain.md` es relacional (usuarios → profesionales/tratamientos/cambios,
  con claves foráneas).
- **Celular:** la base local es la **fuente de verdad para la UI**
  (`architecture.md` §4); necesita transacciones atómicas para la cola de
  respaldo (outbox) y consultas por fecha (línea de tiempo).

## Decisión

1. **PostgreSQL** en el servidor (mismo motor en dev —ya corre en
   `docker-compose`— y en producción).
2. **Drift sobre SQLite** en el celular, con migraciones versionadas.

## Consecuencias

- ✅ Relacional acá y allá: las reglas y los joins del modelo encajan directo.
- ✅ La cola outbox se implementa con transacciones SQL reales.
- ✅ `pgx` (Go) y Drift (Dart) son las opciones maduras de cada ecosistema.
- ⚠️ Dos stacks de acceso a datos (SQL en Go, Drift en Dart) — aceptado:
  son dos hexágonos distintos.

## Alternativas descartadas

- **SQLite en el servidor:** concurrencia y respaldos a mano; migración
  posterior obligatoria.
- **MongoDB/NoSQL:** modelo relacional con claves foráneas; documentos encajan mal.
- **Hive/Isar (celular):** formato propio; la cola outbox y las consultas
  por fecha son más flojas que con SQL.
- **Solo preferencias/JSON (celular):** no sustituye una base para U15 ni
  para transacciones.
