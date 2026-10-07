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

**Fase 1 · Identidad — completada:**

- Registro, login, refresco de sesión y logout (U1–U3).
- Contraseña guardada con **bcrypt** (nunca en claro, R8).
- **Access token JWT** (15 min) + **refresh token** revocable con rotación
  (tabla `sessions`, ADR 004).
- Middleware que exige `Authorization: Bearer <token>` en rutas privadas.

**Siguiente:** Fase 2 de construcción — Tratamientos y profesionales (U4–U11).

### API disponible

| Método | Ruta | Qué hace |
|---|---|---|
| `GET` | `/salud` | Chequeo de servidor + base de datos |
| `POST` | `/auth/registro` | Crear cuenta (`email`, `clave`) |
| `POST` | `/auth/login` | Iniciar sesión → `acceso` + `refresco` |
| `POST` | `/auth/refresh` | Rotar el refresh token |
| `POST` | `/auth/logout` | Cerrar sesión (revoca el refresh) |
| `GET` | `/auth/yo` | Datos de la cuenta (requiere token) |

## Cómo correrlo

Necesitás tener instalados **Docker** y **Go** (y **Flutter** para la app).

1. Levantar la base de datos y esperar a que esté lista:

   ```sh
   docker compose up -d --wait
   ```

   La base de **desarrollo** no usa contraseña y escucha solo en `127.0.0.1`.
   La primera vez se aplican solas las migraciones de `backend/migrations`.

2. (Opcional) Copiar `.env.example` a `.env` y completar `JWT_SECRET`. Si no lo
   hacés, el servidor genera un secreto aleatorio en cada arranque (las sesiones
   no sobreviven a un reinicio). `.env` no se sube al repositorio.

3. Arrancar el backend:

   ```sh
   cd backend
   make run
   ```

4. Abrir en el navegador:

   ```
   http://localhost:8080/salud
   ```

   Vas a ver: `{"estado":"ok"}` (si la base está viva).

5. Correr las pruebas del backend:

   ```sh
   cd backend
   make test
   ```

6. Para apagar la base de datos:

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
