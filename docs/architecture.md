# Transi — Arquitectura (Fase B)

> **Qué es este documento:** cómo se organiza el código de Transi — puertos,
> adaptadores, casos de uso, pruebas y la arquitectura offline-first.
> Se deriva del dominio en [`domain.md`](domain.md). Si hay conflicto,
> primero se decide en `domain.md`.
>
> **Cómo se llegó:** lecciones B1–B5 con checkpoints aprobados (tabla al final).

---

## 1. Los dos hexágonos

El patrón puertos/adaptadores se aplica **una vez en el celular y una vez en el
servidor**, conectados por HTTP/JSON:

```
┌─────────────── CELULAR ────────────────────┐        ┌────────────── SERVIDOR ──────────────────┐
│                                            │        │                                          │
│  pantallas ──► casos de uso ──► PUERTOS    │  JSON  │  handler HTTP ◄── casos de uso ──► PUERTOS│
│   (UI)         (lógica del      (interfaces)│ ◄────► │  (adaptador        (aplican          (interfaces)
│                usuario)                    │  HTTP  │   de entrada)       reglas)               │
│                             ▲              │        │                             ▲             │
│                   adaptadores:             │        │                   adaptadores:            │
│                   BaseLocal* ──────────────┼────────┼──►  Postgres*                             │
│                    (fuente de verdad)      │        │     ArchivoAlmacen* (disco/nube)          │
│                   + RespaldoSinc*          │        │     + almacen de respaldos                │
│                    (bajo demanda)          │        │                                          │
└────────────────────────────────────────────┘        └──────────────────────────────────────────┘
```

### La regla de la flecha (B1)

- El **puerto** es un contrato: dice *qué* necesita la app, sin mencionar tecnología.
- El **adaptador** es quien lo cumple concretnamente (Postgres, base local, RAM, un falso para tests).
- **La dependencia apunta hacia adentro:** adaptador → puerto. El núcleo
  (dominio, casos de uso) **jamás** conoce un adaptador.

### Analogía del restaurante

El **menú** es el puerto (qué se puede pedir); el **cocinero** es el adaptador
(quién lo prepara). El cocinero conoce el menú; el menú no conoce al cocinero.
Cambiar de cocinero no cambia el menú.

### Motivo (por qué existe esto)

Protege las decisiones **todavía no tomadas** (dónde guardan los archivos, si
habrá offline de verdad, qué base de datos) y permite probar la lógica sin red
ni base de datos. Costo honesto: más archivos y carpetas — por eso existe la
sección 6 (dónde NO aplicarlo).

---

## 2. Puertos

### Servidor

| Puerto | Responsabilidad |
|---|---|
| `UsuarioRepositorio` | Cuentas: crear, buscar por email |
| `TratamientoRepositorio` | Guardar, buscar, listar, desactivar tratamientos |
| `CambioRepositorio` | Guardar, buscar, listar, desactivar cambios |
| `ArchivoAlmacen` | `subir(archivo) → id`, `bajar(id)`, `borrar(id)` — esconde "¿disco o nube?" |

> **Fase 11:** se eliminó `ProfesionalRepositorio`. El profesional vive como
> texto dentro del tratamiento, así que no necesita puerto propio.

### Celular

Cada repositorio del servidor tiene su par local:

| Puerto (cliente) | Adaptador local | Adaptador remoto |
|---|---|---|
| Mismos 4 puertos | Base de datos del dispositivo (**fuente de verdad para la UI**) | API HTTP (para respaldo) |

Las pantallas y casos de uso del celular **nunca** hablan JSON directamente:
llaman a un puerto. Si mañana hay otro mecanismo de respaldo, cambian adaptadores.

---

## 3. Casos de uso

### Lista del MVP (U1–U16)

| # | Caso de uso | Reglas / notas |
|---|---|---|
| U1 | Registrarse | Email único; contraseña ≥ 8; solo hash (R8) |
| U2 | Iniciar sesión | Requiere red (decisión B4) |
| U3 | Obtener quién soy | Token válido |
| ~~U4–U7~~ | ~~Profesionales~~ | **Eliminados en Fase 11**: el profesional es un dato del tratamiento (U8) |
| U8 | Crear tratamiento | R2, R6, R7; profesional opcional (texto) |
| U9 | Editar tratamiento (incluye cerrar) | R2 al cambiar fechas |
| U10 | Listar tratamientos | Por usuario; opcional por estado/rango |
| U11 | Desactivar tratamiento | R5 |
| U12 | Registrar cambio | R3, R4; orquesta `ArchivoAlmacen` + `CambioRepositorio`; **compensación**: si falla la ficha, se borra el archivo subido |
| U13 | Listar cambios | Por usuario y rango |
| U14 | Editar / desactivar cambio | R4 también al editar |
| U15 | Consultar línea de tiempo | Une tratamientos + cambios por fecha. **Sin tabla propia**: es una consulta de lectura |
| U16 | Respaldar / restaurar | Respaldo **bajo demanda** (ver sección 4) |

### Mapa de correspondencia

| Acción de Tina | Caso (celular) | Endpoint | Caso (servidor) | Adaptador |
|---|---|---|---|---|
| Guardar tratamiento | U8 local | `POST /tratamientos` | U8 | → Postgres |
| Registrar cambio con foto | U12 local | `POST /cambios` (multipart) | U12 | → ArchivoAlmacen + BD |
| Ver línea de tiempo | U15 local (base local) | — (lee local siempre) | — | → BD local |
| Respaldar | U16 | `PUT /respaldos` | U16 | → ArchivoAlmacen/BD |
| Restaurar en equipo nuevo | U16 | `GET /respaldos` | U16 | → BD |

El cliente valida **por UX** (errores al toque, sin viaje de red); la verdad de
las reglas vive en el servidor y en el dominio — nunca solo en la pantalla.

---

## 4. Arquitectura offline-first

### Principio

> **La base local del celular es la fuente de verdad para la UI.**
> Guardar nunca espera a respaldar. El servidor es una caja de respaldo a la
> que se accede a propósito.

### Flujo de escritura (offline siempre)

```
U12 RegistrarCambio (celular):
    1. guardar cambio + archivos EN LA BASE LOCAL   ← instantáneo, sin red
    2. marcar syncState = "pendiente"
    3. encolar la operación en la cola de salida (misma transacción)
    4. mostrar "guardado" a Tina
```

- **Atomicidad:** guardar y encolar ocurre en **una transacción** o no ocurre nada.
- **Idempotencia:** cada operación lleva `id` propio; el servidor hace *upsert*.
  Recibir la misma operación dos veces = una vez (los reintentos son normales).

### Respaldo bajo demanda (decisión B5 — no sync en segundo plano)

- La app **no** sincroniza en background de forma permanente.
- Sube al servidor solo cuando:
  1. Tina toca **"Respaldar ahora"**, o
  2. lo activó opcionalmente ("respaldar con WiFi").
- **Restaurar** = en el equipo nuevo, "Restaurar respaldo" → baja todo.
- Uso previsto: **migración de equipo** (cambio de celular / iPad), nunca
  dos dispositivos activos en paralelo → conflictos triviales: **gana el
  último respaldo**.

### Reglas mecánicas del respaldo

| Regla | Por qué |
|---|---|
| **Archivo antes que referencia** | El servidor no debe recibir una referencia a un archivo que todavía no existe |
| **FIFO + `actualizadoEn`** | Respetar el orden de las operaciones sobre el mismo registro |
| **Reloj del servidor** | Ante empates, el servidor anota `recibidoEn` y desempata con su propio reloj (los relojes de dispositivos desfían) |
| **Borrados = ediciones** | Como R5 prohíbe borrado físico, un "borrar" es poner `activo=false`: una operación más, sin *tombstones* |
| **Sesión** | El token vive guardado en el celular; si vence, el respaldo espera y la cola queda intacta. Los datos nunca se pierden por un token |
| **Reanudable** | Si el respaldo falla a mitad, la cola sigue pendiente; el próximo intento retoma desde donde quedó |

### Estados de sincronización (dato, no regla de negocio)

`pendiente | respaldado | error` — vive en el celular, informa UI
("subiendo 1 de 2...", "último respaldo: hoy 10:32").

---

## 5. Estrategia de pruebas

La pregunta no es "qué framework" sino **"¿qué se rompe aquí y cómo lo
detecto antes que Tina?"**:

| Capa | Qué protege | Cómo | Ejemplo |
|---|---|---|---|
| Dominio | Reglas R1–R8 | Unitario, sin externos | `NuevoTratamiento` rechaza `fin < inicio` |
| Casos de uso | Orquestación y errores | Unitario con adaptadores **falsos** | U12: si falla la ficha → se compensa borrando el archivo |
| Respaldo (U16) | Idempotencia, orden, reanudación | Dos bases falsas (local + servidor), sin red | Fallo 2 veces y reintento → sin duplicados |
| Adaptador SQL | Que el SQL es correcto | Integración con Postgres real (Docker) | `Guardar` → `ListarPorUsuario` → aparece |
| Handler HTTP | JSON ↔ casos de uso, códigos | `httptest` | Request inválido → 400; éxito → 201 |
| Adaptador cliente | Entender la respuesta del servidor | HTTP simulado | 500 → error claro en UI |
| Pantallas | Estados vacío/cargando/error | Widget test con repositorio falso | Lista vacía muestra CTA |
| Punto a punto | El conjunto | **Checklist manual** en el MVP | Registrar → crear cambio con foto → verlo en timeline |

Distribución sana: la mayoría, rápidos (sin red/Docker/emulador); solo el SQL
necesita servidor real. **Un test que tarda minutos no se corre; si no se corre,
no protege nada.**

---

## 6. Decisiones de NO hacer (triaje anti-sobre-ingeniería)

Toda abstracción se justifica con ① una decisión futura que proteger o
② una regla de negocio que vive ahí. Si no: **código simple**.

| Pieza | Se hace simple así... | Prohibido |
|---|---|---|
| Contraseña | Librería estándar (`bcrypt`/`argon2`) | Criptografía propia; reversible |
| Sesión | JWT u opaco estándar | Protocolo OAuth propio |
| Especialidad del profesional | Texto libre | Tabla/enum/CRUD de especialidades |
| Línea de tiempo | Función que junta dos listas ordenadas | Event sourcing, CQRS, proyecciones |
| Configuración | Variables de entorno en `main.go` | Frameworks de config de 5 capas |
| Logs | `log`/`log/slog` estándar | Stack ELK/observabilidad |
| Errores | `errors.Is/As` | Jerarquías de 4 niveles |
| Subida de archivos | Un adaptador con 2 implementaciones | Plataforma de assets/CDN |
| Email | Validación de formato + unicidad | Verificación en dos fases, servicios externos |
| Dependencias Go | Mínimas (driver BD, UUID, bcrypt, CORS) | ORM mágico, contenedor de DI, framework que decide por vos |
| Flutter | Riverpod simple + pantallas | BLoC de 4 archivos/pantalla, Clean Arch de 6 capas copiada de tutorial |

**Regla del día a día:** código simple y obvio > arquitectura que nadie
entiende. Al dudar: simple; si duele después, se extrae el puerto entonces.
Extraer es fácil; quitar complejidad de más, caro.

---

## 7. Checkpoints registrados (Fase B)

| Checkpoint | Decisión |
|---|---|
| **B1** | Puerto = contrato del *qué*; adaptador = quién lo cumple; dependencia adaptador → puerto |
| **B2** | Casos de uso **U1–U15** completos; U12 con compensación |
| **B3** | Contraseña = librería estándar; timeline = función simple; tabla "NO hacer" obligatoria |
| **B4** | **Offline completo desde el MVP**; login con red la primera vez; después todo local |
| **B5** | **Respaldo bajo demanda** (botón / WiFi opcional), uso **solo migración-restaurar**, no sync permanente; conflictos = gana el último respaldo |

---

## 8. Pendiente — Fase C (decisiones de stack)

Todavía **no** están elegidos: plataforma móvil, lenguaje/framework de
servidor, base de datos del servidor, librería de auth, proveedor de
despliegue y almacenamiento de respaldos/archivos. Se deciden en la Fase C
con el criterio de A–B, y cada una queda registrada como ADR en `docs/adr/`.
