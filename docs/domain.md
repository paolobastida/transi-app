# Transi — Documento de Dominio (Fase A)

> **Qué es este documento:** la base sobre la que se construye todo lo demás.
> Si una decisión técnica futura contradice algo de acá, se cambia *primero* acá.
>
> **Cómo se llegó:** lecciones cortas (A1–A4) con checkpoints aprobados por el equipo.
> Cada decisión queda registrada al final, en la tabla de checkpoints.

---

## 1. Usuarios y flujos (A1)

### Persona primaria

**① Quién recién empieza** ("Tina", 24) — acaba de iniciar un tratamiento hormonal,
está atenta a cada cambio y hoy anota todo en notas desordenadas del celular.
Quiere ordenar esa información y poder verla con el tiempo.

> Cuando haya tensiones de diseño (no se puede optimizar para todos),
> se prioriza: **que quien recién empieza pueda registrarlo todo sin fricción**.

Otras personas hipotéticas (no se optimizan en el MVP, pero no las rompemos):

- **② Quién lleva tiempo** ("Marco"): revisitar su evolución en la línea de tiempo.
- **③ Equipo plural** ("Lucía"): varios profesionales; se cubre porque
  los tratamientos pueden apuntar a distintos profesionales.

### Flujos del MVP

| # | Flujo | Notas |
|---|-------|-------|
| F1 | **Registrar usuario** | Con autenticación (cuenta email + contraseña). Puerta de todo lo demás. |
| F2 | **Registrar tratamiento** | Nombre, dosis, frecuencia, fechas y profesional (opcional). Se pueden cargar **varios medicamentos** de una: cada uno se guarda como un tratamiento que comparte fechas y profesional. |
| F3 | **Registrar cambios físicos** | Texto corto + adjuntos: **fotos** y **notas de voz**. Registro rápido (≤30 s). |
| F4 | **Línea de tiempo** | Ver evolución: tratamientos + cambios ordenados por fecha, filtrable. |

### Fuera del MVP (backlog)

- Preparar cita / resumen para el profesional.
- Recordatorios de dosis (notificaciones).
- Gráficas y métricas de evolución.
- Modo offline / sincronización.
- Exportación de datos.

---

## 2. Glosario — lenguaje ubicuo (A2)

Cada palabra significa **exactamente una cosa** en la app, en el código y en las
conversaciones. Si cambia el significado, cambia el nombre.

| Término | Significado único |
|---------|-------------------|
| **Usuario** | Persona con cuenta (email + contraseña) que usa Transi. Todo lo demás le pertenece a *un* usuario. |
| **Tratamiento** | Lo que la persona consume/administra: nombre, dosis, frecuencia, fecha de inicio y opcionalmente fecha de fin. Es **libre y general**: sirve para cualquier medicamento. |
| **Medicamento** | Cada uno de los ítems que una persona carga de una vez al registrar un tratamiento: se guardan como **tratamientos separados** que comparten fechas y profesional. |
| **Profesional de salud** | Quién indicó un tratamiento. Se guarda **dentro del tratamiento** (nombre + especialidad, texto opcional), sin ficha ni tabla aparte. |
| **Cambio** | Un hecho **físico** documentado en una fecha, con una descripción de texto y adjuntos opcionales. |
| **Descripción (del cambio)** | El único campo de texto del cambio. Aquí la persona puede escribir lo emocional si lo desea — no existe categoría "emotional". |
| **Adjunto** | Archivo pegado a un cambio: **foto** o **nota de voz** (audio). |
| **Línea de tiempo** | Vista cronológica (más reciente arriba) que une tratamientos y cambios. **No es una tabla**: es una consulta de lectura. |
| **Evolución** | Lo que la línea de tiempo deja ver a lo largo del tiempo. En el MVP: ordenada y filtrable por fechas. |
| **Activo / finalizado** | Estado de un tratamiento, **derivado** de `fechaFin` (no se guarda como campo). |
| **Borrado lógico** | Desactivar/ocultar un registro sin destruirlo. El historial médico nunca se borra físicamente. |

---

## 3. Modelo de datos y reglas de negocio (A3)

### Entidades

```
Usuario                                 Tratamiento
├─ id (UUID)                            ├─ id (UUID)
├─ email            (único)             ├─ usuarioId
├─ contraseña (solo hash)               ├─ nombre            (ej: "Estradiol")
└─ fechaRegistro                        ├─ dosis             (ej: "2 mg")
        │                               ├─ frecuencia        (ej: "cada día")
        │ 1                             ├─ fechaInicio
        ├──────── N ─────────────────── ├─ fechaFin          (null = activo)
        │                               ├─ via               (opcional)
        │                               ├─ presentacion      (opcional)
        │                               ├─ dosisCantidad     (opcional)
        │                               ├─ dosisUnidad       (opcional)
        │                               ├─ indicacion        (opcional)
        │                               ├─ profesionalNombre (opcional)
        │                               └─ profesionalEspecialidad (opcional)
        │
        │ 1                             Cambio
        ├──────── N ─────────────────── ├─ id (UUID)
        │                               ├─ usuarioId
        │                               ├─ fecha
        │                               ├─ descripción       (texto; acá puede ir lo emocional)
        │                               │
        │                               │ 1
        │                               └──────── N ──────── Adjunto
        │                                                   ├─ id (UUID)
        │                                                   ├─ tipo       (foto | audio)
        │                                                   └─ archivo    (referencia al contenido)
```

> **El profesional no es una entidad.** Vive *dentro* del tratamiento como
> nombre + especialidad (texto opcional). Registrarlo ahí responde la pregunta
> real ("¿quién me atiende?") sin obligar a gestionar una ficha aparte.

### Reglas de negocio

| # | Regla | Dónde se respeta |
|---|-------|------------------|
| R1 | Un usuario solo ve y edita **sus** datos | Siempre filtrando por `usuarioId` al consultar y al mutar |
| R2 | Un tratamiento con `fechaFin` exige `fechaFin ≥ fechaInicio` | Modelo (lugar de la verdad) + validación en formularios |
| R3 | Un cambio no puede tener fecha futura | Modelo |
| R4 | Un cambio necesita **al menos uno**: descripción no vacía **o** ≥1 adjunto | Modelo |
| R5 | Nada del historial se borra físicamente: los tratamientos y cambios se **desactivan**, no se eliminan | Borrado lógico (`activo`) |
| R6 | Un tratamiento requiere nombre, dosis, frecuencia y fecha de inicio | Modelo |
| R7 | El profesional es **opcional** y se guarda como texto dentro del tratamiento | Modelo (alta sin fricción) |
| R8 | La contraseña se guarda **solo como hash** irreversiblemente; nunca en claro ni en logs | Adaptador de identidad |

### Principios de modelado aplicados

- **Estado derivado, no guardado:** "activo/finalizado" se deduce de `fechaFin`.
  Si se puede derivar, no se guarda (evita datos que se contradicen).
- **Regla cerca del dato:** la verdad de una regla vive en el modelo; los
  formularios también la validan, pero por UX, no por seguridad.

---

## 4. Mapa de contextos (A4)

```
┌─────────────────────────┐
│  ① Identidad            │  Registro, login, sesión.
│  (cuentas)              │  "Usuario" = cuenta con email/contraseña.
│  Se construye primero   │  Sin esto, nada sabe de quién son los datos.
└───────────┬─────────────┘
            │ todos los contextos filtran por el usuario en sesión
            ▼
┌─────────────────────────┐       ┌─────────────────────────┐
│  ② Tratamientos         │       │  ③ Cambios              │
│  Tratamiento            │       │  Cambio, Adjunto        │
│  (profesional como dato)│       │  (texto + fotos/audio)  │
└───────────┬─────────────┘       └───────────┬─────────────┘
            │                                 │
            │        ┌─────────────────┐      │
            └───────►│  ④ Línea de     │◄─────┘
                     │     tiempo      │  Sin datos propios:
                     │  (solo lectura) │  CONSULTA que une ② y ③
                     └─────────────────┘
```

**Criterio de corte:** un contexto = una zona donde una palabra significa una sola
cosa y las decisiones se toman sin consultar a los demás. ② y ③ cambian por
razones distintas (ajustes médicos vs. registro diario) y crecen independientes.

**Lo que NO lleva diseño elaborado** (evitar sobre-ingeniería):

- Email/contraseña: estándar probado (hash + token), nunca criptografía propia.
- Subida de archivos: un adaptador simple, no un "sistema de assets".
- Especialidad del profesional: texto libre por ahora.
- Notificaciones, métricas, exportación: backlog, fuera del MVP.

---

## 5. Decisiones registradas (checkpoints aprobados)

| Checkpoint | Decisión |
|------------|----------|
| **A1** — Flujos MVP | Registrar usuario (con auth) · registrar tratamiento · registrar cambios con fotos y voz · línea de tiempo. Fuera: preparar cita, recordatorios. |
| **A1** — Prioridad | Persona primaria: **quien recién empieza** (Tina). |
| **A2** — Cambios | Solo **físicos**; lo emocional va opcionalmente en la descripción. No existe campo "categoría". |
| **A2** — Profesional | ~~Entidad propia con ficha~~ → **revisado en A5**: pasa a ser un dato de texto del tratamiento. |
| **A2** — Notas | **Un solo campo de texto** por cambio (descripción). |
| **A3** — Validación | Un cambio requiere descripción no vacía **o** ≥1 adjunto. |
| **A3** — Profesional en tratamiento | **Opcional** (R7). |
| **A3** — Borrado | **Nada del historial se borra físicamente** → borrado lógico (R5). |
| **A4** — Contextos | Mapa ①Identidad ②Tratamientos ③Cambios ④Línea de tiempo **aprobado tal cual**. |
| **A5** — Tratamiento libre y general | El tratamiento sirve para **cualquier medicamento**. Se cargan **varios medicamentos** de una (uno por tratamiento, con fechas y profesional compartidos). Campos opcionales: vía, presentación, dosis estructurada e indicación. |
| **A5** — Profesional | Deja de ser entidad: se registra **dentro del tratamiento** (nombre + especialidad en texto), sin tabla ni pantalla propia. |

---

## 6. Pendientes deliberados

Estas preguntas se responden en la **Fase C** (decisiones de stack), no ahora:

- Plataforma móvil, backend, base de datos, despliegue.
- Dónde viven los archivos de fotos y notas de voz.
- Límites concretos de adjuntos (tamaño máximo, duración máxima de audio, formatos).
- Diseño de la autenticación (token, duración de sesión, HTTPS).
