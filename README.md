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

- Backend Go con arquitectura hexagonal, PostgreSQL en `docker-compose.yml`.
- Migración `001_users`, `GET /salud` con *ping* real a la base, tests y CI.
- Proyecto Flutter en `app/`.

**Fase 1 · Identidad — completada (U1–U3):**

- Registro, login, refresco de sesión y logout.
- Contraseña con **bcrypt** (R8); **JWT** de acceso + **refresh revocable** con
  rotación (tabla `sessions`, ADR 004); middleware `Authorization: Bearer`.

**Fase 2 · Tratamientos y profesionales — completada (U4–U11):**

- CRUD de ambos, con R1 (solo lo propio), R2 (fechas), R5 (borrado lógico),
  R6 (campos obligatorios) y R7 (profesional opcional).
- El estado *activo/finalizado* se **deriva** de la fecha de fin.

**Fase 3 · Cambios y archivos — completada (U12–U14):**

- Cambios con foto/nota de voz (`multipart`) y R3/R4.
- Subida al puerto `ArchivoAlmacen` (disco local en desarrollo, ADR 005) con
  **compensación** para no dejar archivos huérfanos.

**Fase 4 · Respaldos del servidor — completada (U16):**

- Subir respaldo completo, recuperar el último y ver el historial.
- El servidor **no interpreta** el respaldo: lo guarda y lo devuelve tal cual.

**Fase 5 · App: cimientos y pantallas de acceso — completada (P1–P2):**

- Estructura `dominio/ · datos/ · presentacion/`.
- Cliente de API con **auto-refresco** del token (401 → renovar → reintentar),
  implementado una sola vez (ADR 004).
- Sesión guardada en el **almacenamiento seguro** del dispositivo.
- Pantallas **P1 Registro** y **P2 Login**, y pantalla de inicio provisional.
- Backend con **CORS** configurable (`CORS_ORIGENES`) para poder previsualizar
  la app en el navegador.

**Siguiente:** Fase 6 — App: profesionales y tratamientos local-first (P4–P7).

### API disponible

| Método | Ruta | Qué hace |
|---|---|---|
| `GET` | `/salud` | Chequeo de servidor + base de datos |
| `POST` | `/auth/registro` | Crear cuenta (`email`, `clave`) |
| `POST` | `/auth/login` | Iniciar sesión → `acceso` + `refresco` |
| `POST` | `/auth/refresh` | Rotar el refresh token |
| `POST` | `/auth/logout` | Cerrar sesión (revoca el refresh) |
| `GET` | `/auth/yo` | Datos de la cuenta (requiere token) |
| `POST` · `GET` | `/profesionales` | Crear / listar profesionales |
| `PUT` · `DELETE` | `/profesionales/{id}` | Editar / desactivar profesional |
| `POST` · `GET` | `/tratamientos` | Crear / listar (`?desde&hasta&estado`) |
| `PUT` · `DELETE` | `/tratamientos/{id}` | Editar (incluye cerrar) / desactivar |
| `POST` | `/cambios` | Registrar cambio (multipart: `fecha`, `descripcion`, `fotos`, `audios`) |
| `GET` | `/cambios` | Listar cambios (`?desde&hasta`) |
| `PUT` · `DELETE` | `/cambios/{id}` | Editar / desactivar cambio |
| `PUT` | `/respaldos` | Subir un respaldo completo |
| `GET` | `/respaldos` | Historial de respaldos |
| `GET` | `/respaldos/ultimo` | Recuperar el último respaldo |

> Salvo `/salud` y `/auth/*`, todos requieren `Authorization: Bearer <access JWT>`.

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

6. Arrancar la app (en el navegador o en un emulador):

   ```sh
   cd app
   flutter run -d chrome
   ```

   Para apuntar a otra dirección del servidor:

   ```sh
   flutter run -d chrome --dart-define=API_BASE_URL=http://192.168.0.10:8080
   ```

7. Para apagar la base de datos:

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
