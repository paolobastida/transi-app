# Transi — Plan de construcción (Fase D)

> Derivado de [`domain.md`](domain.md), [`architecture.md`](architecture.md)
> y los ADRs de `docs/adr/`. Si algo acá contradice esos documentos, primero
> se decide allí.

---

## 1. Mapa de pantallas (Flutter) — D1 aprobado

```
APP
├── AUTH
│   ├── P1  Registro            → U1
│   └── P2  Login               → U2  (requiere red)
│
├── PRINCIPAL (BottomNavigationBar + FAB)
│   ├── P3  Línea de tiempo     → U15  (pestaña inicial; filtro por rango;
│   │                                estados vacío/cargando/error)
│   ├── P4  Tratamientos        → U10  (activos/finalizados)
│   ├── P5  Profesionales       → U5
│   └── [FAB] Registrar cambio  → P8   (a un toque, siempre)
│
├── FORMULARIOS
│   ├── P6  Alta/edición tratamiento  → U8/U9
│   ├── P7  Alta/edición profesional  → U4/U6
│   ├── P8  Registrar cambio          → U12 ⭐ (descripción, foto, nota de voz,
│   │            fecha=hoy; guardar NUNCA espera red)
│   └── P9  Detalle (cambio/tratamiento) → U14/U9/U11/U14 (desactivar)
│
└── CUENTA
    └── P10 Cuenta y respaldo    → U3 + U16
         (sesión, "Respaldar ahora"/"Restaurar", último respaldo + pendientes)
```

Decisiones de diseño: prioridad Tina (FAB a un toque, fecha prellenada);
P3–P9 leen/escriben **solo la base local**; sin "borrar" visible, solo
**desactivar** (R5); sin red solo se ven afectados P2 y P10.

---

## 2. API del servidor — D2 aprobado

Convenios: `/api/v1`, JSON, fechas ISO-8601, UUID,
`Authorization: Bearer <access JWT>`,
error: `{"error": {"codigo", "mensaje"}}`.

| Grupo | Endpoints |
|---|---|
| **Auth** | `POST /auth/registro` · `POST /auth/login` · `POST /auth/refresh` · `POST /auth/logout` |
| **Profesionales** | `GET|POST /profesionales` · `PUT|DELETE /profesionales/{id}` (DELETE = lógico) |
| **Tratamientos** | `GET|POST /tratamientos` (`?desde&hasta&estado`) · `PUT|DELETE /tratamientos/{id}` |
| **Cambios** | `GET|POST /cambios` (`?desde&hasta`; POST = **multipart** con archivos) · `PUT|DELETE /cambios/{id}` |
| **Respaldos** | `PUT /respaldos` (snapshot completo → bucket) · `GET /respaldos/ultimo` (restaurar) · `GET /respaldos` (historial) |
| **Health** | `GET /salud` |

**Ausencias intencionales:** sin `GET /timeline` (P3/U15 lee la base local)
y sin sync incremental (B5: respaldo completo bajo demanda).

Reglas server-side: R2/R6/R7 en tratamientos (`400`), R3/R4 en cambios,
R5 en todo DELETE (**siempre borrado lógico**), R8 (solo hash).
POST `/cambios`: archivos al bucket **primero**, luego la ficha; si falla →
**compensación** (borrar los archivos subidos).

---

## 3. Fases de construcción — D3 aprobado

Cada fase deja algo **funcionando y verificable**.

| # | Fase | Verificación al cerrar |
|---|---|---|
| **0** | Cimientos: estructura hexagonal backend, migración `001_users`, `/salud` con ping a BD, proyecto Flutter, CI (`go test` + `flutter analyze`) | Tests verdes; `/salud` con BD viva |
| **1** | Identidad: U1–U3 (JWT + bcrypt + rotación de refresh, tabla `sessions`) | Cadena `curl`: registro → login → refresh → logout |
| **2** | Tratamientos y profesionales: U4–U11 con R2/R5/R6/R7 | `curl` CRUD completo + tests de reglas |
| **3** | Cambios y archivos: U12–U14 multipart → `ArchivoAlmacen` (disco en dev, bucket en prod) con compensación | `curl` con foto real; sin archivos huérfanos |
| **4** | Respaldos servidor: U16 `PUT/GET /respaldos` | PUT snapshot → GET idéntico |
| **5** | App cimientos + auth: estructura de features (domain/data/presentation), esquema Drift, API client con auto-refresh, P1–P2 | Registro y login en emulador |
| **6** | App profesionales y tratamientos: P4–P7 local-first + estados + widget tests | **Modo avión**: crear y ver tratamiento |
| **7** | App cambios con medios: P8 (cámara/micrófono + permisos), P9 | **Modo avión**: cambio con foto y voz |
| **8** | Línea de tiempo: P3 con filtro de fechas | Evolución visible con datos de prueba |
| **9** | Respaldos en la app: cola outbox atómica, U16, P10, tests con doble fake | **Prueba madre**: respaldar → borrar app → restaurar → todo igual |
| **10** | Pulido y despliegue: checklists, Dockerfile + VPS (Caddy/HTTPS, firewall, respaldos de PG), APK | Dispositivo real con HTTPS |

**Atraviesa todas las fases:** tests por capa (falsos unitarios, integración
SQL, widget tests) y CI desde la Fase 0.

**Riesgos a vigilar:** permisos de cámara/micrófono (F7) y el modo avión
de punta a punta (F9).

---

## 4. Decisiones registradas en esta fase

| Checkpoint | Decisión |
|---|---|
| D1 | Mapa de pantallas P1–P10 aprobado |
| D2 | API (16 endpoints; sin timeline server, sin sync incremental) aprobada |
| D3 | Plan de 11 fases (0–10) aprobado |
