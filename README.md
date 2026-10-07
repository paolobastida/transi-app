# Transi

Transi es una app para que personas transgénero registren sus tratamientos con
distintos profesionales de salud y documenten su evolución en el tiempo.

Este repositorio tiene dos partes:

- `backend/` — el programa que guarda y entrega los datos (lenguaje **Go**).
- `app/` — la aplicación que se usa en el celular (lenguaje **Dart/Flutter**).

## Estado actual

**Diseño (Fases A–D) completado:**

- **A · Dominio:** [`docs/domain.md`](docs/domain.md) — glosario, modelo, reglas, contextos.
- **B · Arquitectura:** [`docs/architecture.md`](docs/architecture.md) — puertos/adaptadores, U1–U16, offline-first, pruebas, "NO hacer".
- **C · Stack:** 6 ADRs en [`docs/adr/`](docs/adr/) — Flutter · Go · PostgreSQL+Drift · JWT · Firebase Storage · VPS.
- **D · Plan:** [`docs/plan.md`](docs/plan.md) — pantallas P1–P10, API, 11 fases de construcción.

**Fase 0 · Cimientos — completada:**

- Backend Go con arquitectura hexagonal (dominio, puertos, casos de uso, adaptadores).
- Migración `001_users` y PostgreSQL en `docker-compose.yml`.
- `GET /salud` que hace *ping* real a la base de datos.
- Tests unitarios (falsos) + test de integración contra PostgreSQL.
- Proyecto Flutter en `app/` con una pantalla mínima.
- CI en [`.github/workflows/ci.yml`](.github/workflows/ci.yml) (pruebas de Go y Flutter).

**Siguiente:** Fase 1 de construcción — Identidad (U1–U3: registro, login,
refresh, logout con JWT + bcrypt).

> Nota: el backend todavía **no** expone los endpoints de negocio (tratamientos,
> cambios, respaldos). Solo `/salud`.

## Cómo correrlo

Necesitás tener instalados **Docker** y **Go** (y **Flutter** para la app).

1. Levantar la base de datos y esperar a que esté lista:

   ```sh
   docker compose up -d --wait
   ```

   La primera vez se aplica la migración `001_users` sola.

2. Arrancar el backend:

   ```sh
   cd backend
   make run
   ```

3. Abrir en el navegador:

   ```
   http://localhost:8080/salud
   ```

   Vas a ver: `{"estado":"ok"}` (si la base está viva).

4. Correr las pruebas del backend:

   ```sh
   cd backend
   make test
   ```

5. Para apagar la base de datos:

   ```sh
   docker compose down
   ```

## Estructura

```
backend/
├── cmd/api/                          # punto de entrada (main.go)
├── internal/
│   ├── dominio/                      # el centro: entidades y reglas
│   ├── puertos/                      # contratos (interfaces)
│   ├── casosdeuso/                   # orquestación (U1–U16)
│   └── adaptadores/
│       ├── entradahttp/              # HTTP (entrada)
│       └── postgres/                 # PostgreSQL (salida)
├── migrations/                       # migraciones SQL
└── Makefile
app/                                  # app Flutter
docs/                                 # diseño (dominio, arquitectura, ADRs, plan)
```
