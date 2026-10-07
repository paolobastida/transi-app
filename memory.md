# Transi — Memoria del proyecto

> **Qué es este documento.** La memoria viva de Transi: qué es, cómo está
> construido, qué se hizo, por qué se decidió así y qué falta. Está escrito para
> que **cualquier persona** (incluida vos, dentro de seis meses) entienda el
> proyecto sin tener que leer todo el código.
>
> **Cómo leerlo.** Si recién llegás, leé las secciones 1–4. Si vas a tocar
> código, andá a las 5–7. Si querés saber el estado y lo que falta, las 11–12.

---

## Índice

1. [Qué es Transi](#1-qué-es-transi)
2. [Cómo está pensado (la arquitectura, en simple)](#2-cómo-está-pensado)
3. [Mapa del repositorio](#3-mapa-del-repositorio)
4. [El dominio: las reglas del negocio](#4-el-dominio)
5. [Qué se construyó, fase por fase](#5-qué-se-construyó-fase-por-fase)
6. [La API del servidor](#6-la-api-del-servidor)
7. [Cómo correrlo y probarlo](#7-cómo-correrlo-y-probarlo)
8. [Seguridad: las decisiones que importan](#8-seguridad)
9. [Estrategia de pruebas](#9-estrategia-de-pruebas)
10. [Problemas que aparecieron y cómo se resolvieron](#10-problemas-y-soluciones)
11. [Estado actual](#11-estado-actual)
12. [Qué falta (Fases 6–10)](#12-qué-falta)
13. [Convenciones y cómo seguir](#13-convenciones)

---

## 1. Qué es Transi

Transi es una app para que **personas transgénero** registren sus tratamientos
con distintos profesionales de salud y documenten su evolución en el tiempo.

La persona que guía las decisiones de diseño es **Tina**: alguien que recién
empieza un tratamiento, que hoy anota todo en notas desordenadas, y que necesita
**registrar sin fricción** (en menos de 30 segundos) y poder **ver su evolución**.

Transi tiene dos partes, cada una con su propio lenguaje:

- **`backend/`** — el servidor, escrito en **Go**. Guarda y entrega los datos.
- **`app/`** — la aplicación del celular, escrita en **Dart/Flutter**.

La idea central es **offline-first** (ver sección 2): la app guarda todo en el
teléfono y el servidor es una caja de respaldo a la que se accede a propósito.

---

## 2. Cómo está pensado

### 2.1 Dos hexágonos separados por HTTP

El proyecto usa el patrón **puertos y adaptadores** (arquitectura hexagonal),
aplicado **una vez en el celular y una vez en el servidor**:

```
   CELULAR (Flutter)                         SERVIDOR (Go)
 pantallas → casos de uso → PUERTOS   ⇄   adaptador HTTP → casos de uso → PUERTOS
                              ▲          JSON/HTTP            ▲
                       adaptadores:                     adaptadores:
                       base local (Drift)               Postgres, disco/nube
```

**La regla de oro:** las dependencias apuntan **hacia adentro**. El núcleo
(dominio + casos de uso) **nunca** sabe si detrás hay Postgres, un archivo en
disco o un falso de pruebas. Eso permite:

- Probar la lógica sin red ni base de datos.
- Cambiar decisiones todavía no tomadas (¿dónde viven los archivos?) sin tocar
  el resto.

**Analogía del restaurante:** el *menú* es el puerto (qué se puede pedir); el
*cocinero* es el adaptador (quién lo prepara). El cocinero conoce el menú; el
menú no conoce al cocinero.

### 2.2 Offline-first

> **La base local del celular es la fuente de verdad para la interfaz.**
> Guardar nunca espera a respaldar.

El respaldo al servidor es **bajo demanda** (Tina toca "Respaldar ahora"), y su
uso previsto es **migración de equipo** (cambiar de celular), no sincronización
permanente. Ante conflictos triviales: gana el último respaldo.

### 2.3 Cómo se llegó hasta acá

El proyecto se pensó en fases de diseño antes de escribir código:

- **Fase A — Dominio** (`docs/domain.md`): glosario, modelo, reglas R1–R8, contextos.
- **Fase B — Arquitectura** (`docs/architecture.md`): puertos/adaptadores, casos de uso U1–U16, offline-first, estrategia de pruebas y una tabla de **"NO hacer"** (anti sobre-ingeniería).
- **Fase C — Stack** (`docs/adr/`): 6 ADRs que fijan las decisiones técnicas.
- **Fase D — Plan** (`docs/plan.md`): pantallas P1–P10, API y 11 fases de construcción.

Después empezó la construcción (Fases 0–5, ver sección 5).

### 2.4 El stack, en una tabla

| Decisión | Elección | Por qué (ADR) |
|---|---|---|
| App móvil | **Flutter / Dart** | Un código para iOS y Android (ADR 001) |
| Servidor | **Go** con `net/http` | Binario único, poca magia, encaja con puertos/adaptadores (ADR 002) |
| Base del servidor | **PostgreSQL** | Modelo relacional con claves foráneas (ADR 003) |
| Base del celular | **Drift/SQLite** (Fase 6) | Fuente de verdad local + transacciones para la cola de respaldo (ADR 003) |
| Autenticación | **JWT de acceso + refresh revocable** | Revocación real sin perder lo bueno de JWT (ADR 004) |
| Archivos | **Firebase Storage** (prod) / **disco** (dev) | Durabilidad de los respaldos (ADR 005) |
| Despliegue | **VPS propio** | Control y costo fijo (ADR 006) |

---

## 3. Mapa del repositorio

```
transi/
├── README.md              # vista rápida y cómo correrlo
├── memory.md              # este documento
├── docker-compose.yml     # PostgreSQL de desarrollo (sin contraseña, solo 127.0.0.1)
├── .env.example           # plantilla de configuración (sin secretos)
├── .github/workflows/ci.yml  # pruebas automáticas en GitHub
│
├── docs/                  # diseño (Fases A–D)
│   ├── domain.md
│   ├── architecture.md
│   ├── plan.md
│   └── adr/               # 001..006
│
├── backend/               # servidor Go
│   ├── cmd/api/main.go    # punto de entrada: lee config y "enchufa" todo
│   ├── internal/
│   │   ├── dominio/       # el centro: entidades y reglas R1–R8
│   │   ├── puertos/       # contratos (interfaces)
│   │   ├── casosdeuso/    # orquestación (U1–U16)
│   │   ├── adaptadores/   # implementaciones concretas
│   │   │   ├── entradahttp/   # HTTP (entrada)
│   │   │   ├── postgres/      # PostgreSQL (salida)
│   │   │   ├── seguridad/     # bcrypt + JWT
│   │   │   └── almacen/       # archivos en disco
│   │   └── pruebas/       # dobles de prueba (falsos) compartidos
│   ├── migrations/        # 001..005 SQL
│   └── Makefile
│
└── app/                   # app Flutter
    ├── lib/
    │   ├── config.dart
    │   ├── dominio/       # modelos (Usuario, Sesion)
    │   ├── datos/         # ApiClient, AlmacenSesion, Autenticacion
    │   └── presentacion/  # pantallas P1, P2 y de inicio
    └── test/
```

**Por qué esta forma:** cada carpeta tiene una responsabilidad. `dominio` no
importa nada de afuera; `adaptadores` importa hacia adentro; `cmd/api` es el
único lugar donde se decide qué adaptador concreto se usa.

---

## 4. El dominio

El **dominio** es el corazón: entidades y reglas de negocio, sin tecnología.
Vive en `backend/internal/dominio/`.

### 4.1 Entidades

| Entidad | Campos clave | Notas |
|---|---|---|
| **Usuario** | id, email (único), contraseña (solo hash), fechaRegistro | Todo lo demás le pertenece |
| **Sesion** | id, usuarioId, hash del refresh, expiraEn | La parte revocable del login |
| **Profesional** | id, usuarioId, nombre, especialidad, activo | Ficha del equipo médico |
| **Tratamiento** | id, usuarioId, nombre, dosis, frecuencia, fechaInicio, fechaFin, profesionalId, activo | `fechaFin` nulo = activo |
| **Cambio** | id, usuarioId, fecha, descripción, activo, adjuntos | Un hecho físico |
| **Adjunto** | id, cambioId, tipo (foto/audio), archivo (referencia) | El contenido vive fuera de la BD |
| **Respaldo** | id, usuarioId, archivo (referencia), creadoEn | "Foto" completa de los datos |

### 4.2 Las reglas de negocio (R1–R8)

| # | Regla | Dónde vive |
|---|---|---|
| R1 | Un usuario solo ve y edita **sus** datos | Toda consulta filtra por `usuarioId` |
| R2 | `fechaFin ≥ fechaInicio` | `dominio/tratamiento.go` (`Validar`) |
| R3 | Un cambio no puede tener fecha futura | `dominio/cambio.go` (`Validar`) |
| R4 | Un cambio necesita descripción **o** ≥1 adjunto | `dominio/cambio.go` (`Validar`) |
| R5 | **Nada del historial se borra físicamente** → borrado lógico | Columna `activo` en todas las tablas |
| R6 | Un tratamiento requiere nombre, dosis, frecuencia y fecha de inicio | `dominio/tratamiento.go` |
| R7 | El profesional es **opcional** en el tratamiento | `profesionalId` puede ser nulo |
| R8 | La contraseña se guarda **solo como hash** | `adaptadores/seguridad/hasher_bcrypt.go` |

**Principio aplicado:** *"estado derivado, no guardado"*. El estado
**activo/finalizado** de un tratamiento **no** es una columna: se deduce de si
`fechaFin` es nulo. Guardarlo sería un dato que se puede contradecir.

---

## 5. Qué se construyó, fase por fase

Cada fase dejó algo **funcionando y verificable**, y se guardó en su propio
commit.

### Fase 0 — Cimientos

- Estructura hexagonal del backend, PostgreSQL en `docker-compose.yml`.
- Migración `001_users`.
- `GET /salud` que hace *ping* real a la base (503 si está caída).
- Proyecto Flutter en `app/`.
- CI de GitHub Actions (`go test` + `flutter analyze`).
- **Verificación:** tests verdes; `/salud` con base viva.

### Fase 1 — Identidad (U1–U3)

- **U1 Registrarse:** email único, contraseña ≥ 8, guardada con **bcrypt**.
- **U2 Iniciar sesión:** verifica contraseña y emite tokens.
- **U3 Quién soy:** datos de la cuenta a partir del token.
- **Refresh token revocable** con rotación (tabla `sessions`).
- Middleware que exige `Authorization: Bearer <token>`.
- **Verificación:** cadena `curl` registro → login → refresh → logout; el token
  viejo deja de servir.

### Fase 2 — Tratamientos y profesionales (U4–U11)

- CRUD completo de ambos, con R1, R2, R5, R6 y R7.
- El profesional de un tratamiento se valida contra el usuario dueño.
- **Verificación:** CRUD con `curl` + tests de reglas.

### Fase 3 — Cambios y archivos (U12–U14)

- Registrar cambio con **foto y/o nota de voz** (`multipart/form-data`).
- R3 y R4 aplicadas; R5 (borrado lógico).
- Puerto `ArchivoAlmacen`; en desarrollo, adaptador de **disco**.
- **Compensación:** si falla guardar la ficha, se **borran** los archivos ya
  subidos (no quedan huérfanos).
- **Verificación:** `curl` con archivos reales; editar y desactivar.

### Fase 4 — Respaldos del servidor (U16)

- `PUT /respaldos` guarda una "foto" completa; `GET /respaldos/ultimo` la
  devuelve **idéntica**; `GET /respaldos` lista el historial.
- El servidor **no interpreta** el respaldo: lo almacena como archivo.
- **Verificación:** subir → recuperar idéntico → historial.

### Fase 5 — App: cimientos y acceso (P1–P2)

- Estructura `dominio / datos / presentacion`.
- **Cliente de API con auto-refresco:** si una petición autenticada responde
  401, renueva el token y reintenta (implementado **una sola vez**, ADR 004).
- Sesión guardada en el **almacenamiento seguro** del dispositivo.
- Pantallas **P1 Registro** y **P2 Login**, más una pantalla de inicio
  provisional con cierre de sesión.
- Backend con **CORS** configurable para poder ver la app en el navegador.
- **Verificación:** `flutter analyze` limpio, widget tests verdes, app servida en
  el navegador.

### Fase 6 — App local-first (P4–P7)

- **Drift** (SQLite) como base de datos local del teléfono: la **fuente de
  verdad** de la interfaz.
- Pantallas **P4 Tratamientos** (filtro activos/finalizados/todos), **P5
  Profesionales** y sus formularios **P6/P7**. Guardan **solo en la base local**:
  no llaman al servidor.
- El arranque de la app **ya no necesita red**: si hay sesión guardada, entra
  directo (offline-first).
- Se agregaron los archivos de Drift para web (`web/sqlite3.wasm` y
  `web/drift_worker.dart.js`).
- **Verificación:** repositorios probados con base en memoria; crear y listar un
  tratamiento funciona sin red.

### Fase 7 — App: cambios con foto y voz (P8–P9)

- Tablas locales `cambios` y `adjuntos` en Drift. El contenido de los archivos se
  guarda como **bytes en la base local**, para funcionar igual en todas las
  plataformas (incluida web).
- **P8 Registrar cambio**: descripción + **foto** (`image_picker`) + **nota de
  voz** (`record`, grabada como stream de bytes). Fecha por defecto hoy.
- **P9 Detalle**: ver descripción, fotos y notas de voz; desactivar (R5).
- Permisos de cámara/micrófono en Android (`AndroidManifest.xml`) e iOS
  (`Info.plist`).
- **Verificación:** repositorios de cambios probados con base en memoria; los
  adjuntos se guardan y recuperan íntegros.

### Fase 8 — Línea de tiempo (P3)

- La pestaña principal une **tratamientos y cambios** por fecha (más reciente
  primero), con **filtro por rango**.
- Es una **consulta de lectura**: no hay tabla de línea de tiempo. Se combinan
  los dos streams locales (helper `_combinar`, equivalente mínimo de
  `combineLatest`, sin dependencias extra).
- **Verificación:** tests de que une, ordena y filtra correctamente.

### Fase 9 — Respaldos desde la app (P10)

- Pantalla **P10 Cuenta y respaldo**: email, último respaldo, pendientes, y
  botones de **respaldar** y **restaurar**.
- El respaldo es un **snapshot completo** (JSON) de los datos locales, con los
  archivos en **base64**, que se sube con `PUT /respaldos` y se baja con
  `GET /respaldos/ultimo`.
- Se agregó la columna `pendiente` a las tablas locales (se marca al escribir, se
  limpia al respaldar) y una tabla `ajustes` para guardar el último respaldo.
  Esto requirió subir `schemaVersion` a 2 con una migración (`addColumn`).
- El acceso remoto está detrás de una interfaz (`RespaldoRemoto`) para poder
  probar con un **doble falso**.
- **Prueba madre** (test): respaldar en una base y restaurar en otra deja todo
  idéntico, incluidos los bytes de los adjuntos.

### Fase 10 — Pulido y despliegue

- `backend/Dockerfile`: build multi-etapa, imagen final mínima (Alpine, usuario
  sin privilegios). **Verificada**: la imagen se construye y arranca, y responde
  `/salud` conectándose a Postgres.
- `docker-compose.prod.yml`: PostgreSQL + servidor + **Caddy** (HTTPS automático
  con Let's Encrypt). Los puertos 80/443 son lo único expuesto.
- `deploy/`: `Caddyfile`, `.env.prod.example` y `respaldar-postgres.sh`
  (respaldos con fecha).
- `docs/despliegue.md`: guía paso a paso (VPS, firewall, dominio, HTTPS,
  respaldos automáticos, actualizaciones, APK).
- CI: se agregó un job que construye la imagen Docker.

> Lo que **no** se puede hacer desde acá: entrar a tu VPS y desplegar, y firmar
> el APK. Eso requiere tus credenciales, un dominio y un keystore.

---

## 6. La API del servidor

Convenciones: prefijo `/api/v1` previsto, JSON, fechas ISO-8601 (`AAAA-MM-DD`
para fechas de calendario), UUID, `Authorization: Bearer <access JWT>`.
Los errores tienen la forma `{"error": {"codigo", "mensaje"}}`.

| Método | Ruta | Auth | Qué hace |
|---|---|---|---|
| `GET` | `/salud` | no | Chequeo de servidor + base |
| `POST` | `/auth/registro` | no | Crear cuenta (`email`, `clave`) |
| `POST` | `/auth/login` | no | Iniciar sesión → `acceso` + `refresco` |
| `POST` | `/auth/refresh` | no | Rotar el refresh token |
| `POST` | `/auth/logout` | no | Cerrar sesión (revoca el refresh) |
| `GET` | `/auth/yo` | sí | Datos de la cuenta |
| `POST` · `GET` | `/profesionales` | sí | Crear / listar |
| `PUT` · `DELETE` | `/profesionales/{id}` | sí | Editar / desactivar |
| `POST` · `GET` | `/tratamientos` | sí | Crear / listar (`?desde&hasta&estado`) |
| `PUT` · `DELETE` | `/tratamientos/{id}` | sí | Editar (incluye cerrar) / desactivar |
| `POST` | `/cambios` | sí | Registrar (multipart: `fecha`, `descripcion`, `fotos`, `audios`) |
| `GET` | `/cambios` | sí | Listar (`?desde&hasta`) |
| `PUT` · `DELETE` | `/cambios/{id}` | sí | Editar / desactivar |
| `PUT` | `/respaldos` | sí | Subir respaldo completo |
| `GET` | `/respaldos` | sí | Historial de respaldos |
| `GET` | `/respaldos/ultimo` | sí | Recuperar el último respaldo |

**Códigos de error típicos:** 400 (datos inválidos o regla de negocio), 401 (sin
token o credenciales malas), 404 (no existe o no es tuyo), 409 (email duplicado),
500 (error interno).

---

## 7. Cómo correrlo y probarlo

Requisitos: **Docker**, **Go** (≥ 1.27) y, para la app, **Flutter**.

```sh
# 1. Base de datos (sin contraseña, solo accesible desde tu máquina)
docker compose up -d --wait

# 2. Servidor
cd backend
make run            # queda escuchando en http://localhost:8080

# 3. Prueba rápida
curl http://localhost:8080/salud      # {"estado":"ok"}

# 4. App (en el navegador)
cd ../app
flutter run -d chrome
```

**Atajos del Makefile del backend:** `make test`, `make db-up`, `make db-down`,
`make build`, `make fmt`, `make vet`.

**Configuración:** copiá `.env.example` a `.env` y completá `JWT_SECRET` si
querés sesiones que sobrevivan reinicios. Sin `.env`, el servidor genera un
secreto aleatorio en cada arranque. `.env` **no** se sube al repositorio.

**Probar en un teléfono real:** ver
[`docs/probar-en-dispositivo.md`](docs/probar-en-dispositivo.md). Requiere el SDK
de Android (o Xcode) y que el teléfono esté en la misma red WiFi que la
computadora; se corre con
`flutter run --dart-define=API_BASE_URL=http://TU_IP:8080`.

---

## 8. Seguridad

Decisiones tomadas (y por qué), porque Transi maneja **datos de salud**:

- **Ninguna contraseña en el repositorio.** La base de desarrollo no usa
  contraseña (`trust`) y escucha **solo en `127.0.0.1`**. El `JWT_SECRET` se
  genera al azar si no se define. La historia de Git fue **reescrita** para
  borrar credenciales que habían quedado en un commit inicial.
- **Contraseñas con bcrypt** (R8): hash irreversible, nunca en claro ni en logs.
- **JWT de acceso corto (15 min) + refresh revocable (30 días)** con rotación:
  cerrar sesión borra el refresh; el acceso muere solo en ≤ 15 min.
- **Refresh guardado como hash** en la base: una fuga de la tabla no expone los
  tokens.
- **R1 aplicado en cada consulta:** siempre se filtra por `usuarioId`, así nadie
  puede leer ni editar datos ajenos.
- **CORS configurable** (`CORS_ORIGENES`): en desarrollo `*`; en producción hay
  que restringirlo.
- **HTTPS obligatorio en producción** (ADR 004/006): sin HTTPS, el JWT no sirve.

---

## 9. Estrategia de pruebas

La pregunta no es "¿qué framework?", sino **"¿qué se rompe acá y cómo lo detecto
antes que Tina?"**.

| Capa | Qué protege | Cómo |
|---|---|---|
| Dominio | Reglas R1–R8 | Unitario, sin externos |
| Casos de uso | Orquestación y compensación | Unitario con **falsos** (`internal/pruebas`) |
| Adaptador SQL | Que el SQL sea correcto | Integración con Postgres real (Docker) |
| Handler HTTP | JSON ↔ casos de uso, códigos | `httptest` |
| Pantallas | Que se rendericen | Widget tests |

**Comandos:**

```sh
cd backend && make test      # unitarios + integración si hay DATABASE_URL
cd app && flutter test
```

Los tests de integración SQL se **saltan** solos si no hay `DATABASE_URL`, para
que los rápidos nunca dependan de Docker. **Un test que tarda minutos no se
corre; si no se corre, no protege nada.**

---

## 10. Problemas que aparecieron y cómo se resolvieron

Estos son aprendizajes reales, no teoría:

1. **El "esqueleto" no existía.** El README y el ADR-002 afirmaban que ya había
   un backend Go funcionando, pero en el repositorio solo estaban los documentos.
   No había Git, así que **no se pudo recuperar**. Se reconstruyó de cero y se
   corrigió el README (un README que miente es peor que no tenerlo).
2. **Contenedores y procesos huérfanos.** Quedaba un contenedor Postgres y un
   servidor Go corriendo del esqueleto perdido, ocupando los puertos 5432 y 8080.
   Eso hacía fallar las pruebas y devolvía respuestas viejas (404). Se limpiaron.
   **Lección:** "el puerto está ocupado" muchas veces significa "hay algo viejo
   vivo".
3. **README desincronizado.** Al actualizar el estado fui reemplazando el bloque
   anterior y borré el historial de fases. Se corrigió listando **todas** las
   fases.
4. **Secretos en la historia de Git.** Un commit inicial contenía la contraseña
   de la base de desarrollo y un secreto JWT por defecto. Como el repositorio
   nunca se subió, se **reescribió la historia** (`git filter-branch`) para
   eliminarlos y se cambió el diseño para no volver a introducirlos.
5. **CORS.** La app en modo web no podía llamar a la API en otro puerto. Se
   agregó un middleware CORS configurable. **Lección:** en web, el navegador
   bloquea peticiones entre orígenes; en móvil, eso no pasa.
6. **Fecha en dos formatos.** Los respaldos se devolvían con hora UTC en un
   endpoint y local en otro. Se normalizó a UTC.

---

## 11. Estado actual

**Diseño (Fases A–D):** completo.

**Construcción (Fases 0–10):** completas y verificadas. **MVP terminado.**

- ✅ Backend completo: identidad, profesionales, tratamientos, cambios con
  archivos y respaldos.
- ✅ App completa: registro/login, base local Drift (profesionales,
  tratamientos, cambios con foto y voz), línea de tiempo y respaldar/restaurar.
- ✅ Paquete de despliegue: Dockerfile, compose de producción con HTTPS (Caddy)
  y respaldos de PostgreSQL.
- ✅ Tests verdes en backend y app; CI configurado (incluida la imagen Docker).
- ✅ Sin credenciales en el repositorio ni en su historia.

**Historial de commits:**

```
<final> Fase 10: Dockerfile, compose de producción con HTTPS y guía de despliegue
373b09e Fase 9: app — respaldos con snapshot completo (P10) y prueba madre
1a867c3 Fase 8: app — línea de tiempo (P3)
cc54ed1 Fase 7: app — cambios con foto y voz (P8–P9)
73c4e7c Fase 6: app local-first con Drift (P4–P7)
3d184cc Fase 5: app Flutter (P1/P2), auto-refresco y CORS
0abdafe Fase 4: respaldos del servidor (U16)
f7d9bd6 Fase 3: cambios y archivos (U12-U14) con compensación
195b9c8 Fase 2: profesionales y tratamientos (U4-U11)
b9333bb Fase 1: identidad (U1-U3) sin credenciales
cafbd5c Fase 0: cimientos
```

**Limitaciones conocidas (honestas):**

- El respaldo es **completo y bajo demanda** (no sincronización incremental), por
  decisión B5.
- Los archivos se guardan en un **volumen de disco** del servidor; el ADR-005
  propone Firebase Storage como destino final (cambiar solo el adaptador).
- El despliegue real en un VPS y la **firma del APK** no se ejecutaron desde acá:
  requieren tus credenciales, un dominio y un keystore (guía en
  `docs/despliegue.md`).

---

## 12. Qué falta

**El MVP (Fases 0–10) está completo.** No queda ninguna fase del plan.

Lo que queda es **ponerlo en producción** (tu parte): desplegar en el VPS y
firmar el APK, siguiendo `docs/despliegue.md`.

### Backlog (fuera del MVP, según `domain.md`)

- Preparar cita / resumen para el profesional.
- Recordatorios de dosis (notificaciones).
- Gráficas y métricas de evolución.
- Exportación de datos.
- Migrar el almacenamiento de archivos a **Firebase Storage** (ADR-005).

### Ideas de mejora técnica

- Migraciones de la app con un runner (hoy Drift migra solo, versión 2).
- Sincronización incremental (hoy el respaldo es completo).
- Reproducir las notas de voz en el detalle (hoy solo se listan).
- Decidir el futuro del login (ver la discusión sobre cuenta opcional).

---

## 13. Convenciones

- **Idioma del código:** nombres de dominio, paquetes y comentarios en
  **español** (el glosario de `domain.md` es el lenguaje ubicuo). Los términos
  técnicos estándar (HTTP, JWT, SQL) quedan como se conocen.
- **Regla del día a día:** *código simple y obvio > arquitectura que nadie
  entiende*. Al dudar, simple; si duele después, se extrae el puerto entonces.
- **No hacer** (de `architecture.md` §6): nada de ORM mágico, contenedor de
  dependencias, event sourcing, CQRS, criptografía propia, frameworks de config
  de 5 capas. Extraer una abstracción es fácil; quitarla de más, caro.
- **Antes de commitear:** `gofmt`, `go vet`, `go test` (backend) y
  `flutter analyze`, `flutter test` (app). El CI corre lo mismo.
- **Nunca** subir `.env` ni secretos. Si dudás, corré
  `git grep -nE 'password|secret|token'` antes de commitear.

---

*Última actualización: Fase 10 completada — MVP terminado.*
