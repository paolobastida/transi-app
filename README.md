# Transi

**Registrá tus tratamientos y tus cambios en un solo lugar. Simple, privado y sin servidor.**

Transi es una app para personas trans que quieren llevar un registro de sus
tratamientos de salud y documentar cómo van cambiando en el tiempo. Nació como
un proyecto real y quedó como pieza de portafolio: una app chica, terminada y
con una decisión de producto clara — **tus datos son tuyos y no salen de tu
dispositivo**.

> **Demo:** `https://TU-USUARIO.github.io/transi/`
> _(reemplazá el link cuando actives GitHub Pages; el workflow ya está incluido)_

[![Pantalla de inicio de Transi](docs/capturas/inicio-desktop.jpg)](docs/capturas/inicio-desktop.jpg)

## La idea

Un tratamiento oncológico, hormonal o de cualquier tipo genera fechas, dosis y
profesionales que se pierden entre mensajes, recetas y memoria. Y los cambios
—físicos, emocionales, los que sean— tampoco suelen quedar registrados en ningún
lado.

Transi resuelve dos cosas y nada más:

1. **Qué estás tomando** y desde cuándo.
2. **Qué cambió** y cómo te sentís al respecto.

Todo en una línea de tiempo, sin planillas ni formularios infinitos.

## Qué podés hacer

- **Línea de tiempo** con tratamientos y cambios, ordenada por fecha y agrupada
  por mes. Filtros por tipo.
- **Tratamientos en curso** siempre visibles arriba, con dosis, frecuencia y
  hace cuánto empezaste.
- **Registrar y editar tratamientos** con **uno o varios medicamentos**. Todos
  comparten las fechas y el profesional, y cada uno tiene su dosis y frecuencia.
- **Recordatorios por medicamento**: cargás los horarios (ej: 08:00 y 20:00) y
  Transi te avisa a la hora de la toma. En las apps nativas de **macOS e iOS**
  quedan programados en el sistema y suenan **aunque la app esté cerrada**; en
  el navegador funcionan mientras esté abierta. No se repiten en el día. Los de
  hoy se ven en **Inicio**, ordenados por hora y con el próximo resaltado.
- **Registrar cambios** con una nota, una foto opcional y una **nota de voz**
  (hasta 60 segundos). La foto se comprime en el navegador y la voz se graba a
  32 kbps, para que decenas de registros sigan entrando sin problema.
- **Exportar e importar** todo como un archivo JSON.
- **Datos de ejemplo** en un clic para ver la app funcionando sin cargar nada.
- **Borrar todo** sin dejar rastros.
- **Instalarla como app (PWA)** en Android, iPhone/iPad o escritorio. Se abre
  sin la barra del navegador y sigue funcionando sin conexión.
- **Ayuda integrada** en lenguaje simple: primeros pasos, qué es un tratamiento
  o un cambio, privacidad, respaldos, recordatorios y cuentas opcionales.

## Qué quedó afuera (a propósito)

La versión anterior de Transi tenía backend en Go, app Flutter, app Tauri,
cuentas, respaldos en la nube y recordatorios. Para el portafolio recorté todo
lo que no se puede mostrar en 30 segundos:

| Quedó afuera | Por qué |
|---|---|
| Servidor | El valor está en los datos, no en el login. Sin servidor no hay base de datos que filtrar, ni sesiones que roten, ni respaldos que se filtren. |
| Cuentas obligatorias | La cuenta es **opcional** y no manda sobre el producto: sin cuenta todo funciona igual. |
| Respaldos en la nube | Se reemplazaron por exportar/importar un JSON. |
| Avisos con la app cerrada en el navegador | La app nativa de macOS los programa en el sistema (`UNUserNotificationCenter`). En el navegador, que suenen con la app cerrada exigiría push y un servidor. |
| Flutter + Tauri | Una sola app web corre en cualquier lado y se prueba con un link. |

## Probar en iPhone (iOS nativo)

Necesitás macOS con Xcode y XcodeGen (`brew install xcodegen`). Para compilar
para el simulador de iPhone 16:

```sh
./ios/build.sh 'platform=iOS Simulator,name=iPhone 16'
open ios/Transi.xcodeproj
```

Para instalarla en un iPhone conectado, abrí el proyecto en Xcode, elegí tu
equipo en **Signing & Capabilities** y ejecutá el esquema `Transi`. La primera
vez que actives recordatorios, aceptá el permiso de notificaciones. Los avisos
son locales al dispositivo: funcionan sin internet y con la app cerrada, pero no
se sincronizan a otros dispositivos. Los datos de Transi permanecen en el
dispositivo.

La versión completa sigue disponible en el tag
[`v1-completa`](https://github.com/TU-USUARIO/transi/tree/v1-completa):
`git checkout v1-completa`.

## La cuenta es opcional (y no manda sobre el producto)

Podés usar Transi **sin cuenta**, como siempre. Pero si querés, podés entrar
con **Google, Apple o Facebook** desde **Ajustes → Tu cuenta**. Los tres botones
están siempre; si falta el Client ID de uno, el botón explica qué variable
configurar y la app sigue funcionando sin cuentas.

Lo que hace y lo que **no** hace:

| | |
|---|---|
| **Sí** | Separa tus datos por cuenta **en este dispositivo**: cada cuenta tiene su propio espacio (`transi.datos.<proveedor>:<sub>`). |
| **Sí** | Al entrar, si tenías registros hechos sin cuenta, te ofrece llevártelos. Nada se borra. |
| **No** | No sincroniza entre dispositivos. El proveedor no recibe **nada** de lo que cargás. |
| **No** | No hay servidor nuestro. |

### Cómo se valida la identidad sin servidor

Es donde un "login con Google" suele meter una base de datos de la que no habla
nadie. Acá no hay ninguna:

- **Google y Apple** entregan un **ID token** (JWT). La app decodifica el payload
  en el navegador y valida `aud` (que el token sea para *esta* app), `iss` (que
  venga de Google o de Apple) y `exp` (que no esté vencido). Sin validar `aud`,
  una credencial válida de otra app podría abrir sesión acá. Esa validación vive
  en `src/jwt.ts` y `src/google.ts` / `src/apple.ts`.
- **Facebook** es distinto: no recibe un JWT, sino que el SDK de JavaScript
  devuelve la sesión y la app le pide el perfil a la Graph API.
- **No se verifica la firma** de los JWT. La firma la garantiza el script del
  proveedor, cargado desde su propio dominio — no hay backend propio que la
  compruebe. Si eso te incomoda, tenés razón: es el costo de no tener servidor,
  y es el motivo por el que **la cuenta es opcional**.
- El perfil se guarda en el `localStorage` y se lee solo para decidir qué espacio
  de datos usar. Cerrar sesión lo borra.

### Configurarla

La app funciona completa sin configurar nada.

```sh
cp .env.example .env      # y completar las variables que quieras usar
```

| Variable | Para qué | Dónde se consigue |
|---|---|---|
| `VITE_GOOGLE_CLIENT_ID` | Google | Console → APIs y servicios → Credenciales → ID de cliente OAuth (tipo *Aplicación web*) |
| `VITE_APPLE_CLIENT_ID` | Apple | developer.apple.com → Identifiers → Services IDs → *Sign In with Apple* |
| `VITE_APPLE_REDIRECT_URI` | Apple | La URL declarada en *Return URLs* de ese Service ID |
| `VITE_FACEBOOK_APP_ID` | Facebook | developers.facebook.com → Mi app → Configuración → Básica |

En todos los casos hay que declarar los orígenes autorizados:
`http://localhost:5173` en desarrollo y `https://TU-USUARIO.github.io` para la
demo. Reiniciá `pnpm dev` después: Vite lee las variables `VITE_*` al arrancar.

> Tanto la pantalla de consentimiento de Google como la revisión de Facebook
> arrancan en modo *Prueba*: solo entran los usuarios que agregues. Para que
> cualquier visitante de la demo pueda entrar, hay que publicar la app.

### Detalles de cada proveedor

- **Google**: creá un *ID de cliente OAuth* de tipo **Aplicación web** y agregá
  los orígenes autorizados. El botón oficial lo dibuja Google Identity Services.
- **Apple**: requiere una cuenta de **Apple Developer** (paga), un *Services ID*
  con *Sign In with Apple*, la *Return URL* declarada y el dominio HTTPS
  verificado con el archivo de asociación en
  `/.well-known/apple-developer-domain-association.txt`. **No funciona en
  `localhost`**: para probarlo necesitás un dominio (o un túnel HTTPS).
- **Facebook**: creá una app en Meta for Developers, declarala en modo *Live* y
  agregá el dominio en **Dominios permitidos para el SDK de JavaScript**. En
  modo desarrollo solo pueden entrar cuentas de prueba.

Los SDK de Apple y Facebook se cargan **solo al abrir Ajustes**; Google carga su
script cuando se dibuja su botón. Ninguno se ejecuta en la pantalla principal ni
recibe los registros de salud.

## Cómo está hecha

- **TypeScript puro + Vite**, sin frameworks de UI. 9.500 líneas entre app,
  estilos y pruebas.
- **localStorage** como única base de datos (`transi.datos`). No hay API, no
  hay cookies, no hay analytics.
- **Fotos comprimidas** con `<canvas>` a un máximo de 1200 px y JPEG 0.78.
- **Notas de voz** con `MediaRecorder`, en MP4/Opus cuando el navegador lo
  permite (WebM como alternativa), con un máximo de 60 segundos.
- **Rutas por hash** (`#/detalle/cambio/123`), así funciona en cualquier hosting
  estático y el botón Atrás hace lo que esperás.
- **Diseño responsive** con layout de una columna en móvil, grilla en tablet y
  panel de dos columnas en escritorio. Respeta áreas seguras (notch) y usa
  objetivos táctiles de 44 px.
- **PWA instalable** con manifiesto, íconos y service worker: red-primero para
  la navegación (así llegan las actualizaciones) y cache-primero para los
  recursos estáticos (así abre sin conexión).
- **Recordatorios de toma**: en la app nativa de macOS se programan con
  `UNUserNotificationCenter` (`UNCalendarNotificationTrigger` diario) y suenan
  con la app cerrada. En el navegador usan `Notification` y un timer cada 20 s
  mientras está abierta. Sin servidor ni push en ningún caso.
- **121 pruebas** con Vitest sobre el modelo, la persistencia, las fechas, la
  grabadora, la cámara, las rutas y los recordatorios.

```
.
├── src/
│   ├── main.ts            # router y arranque
│   ├── rutas.ts           # rutas por hash
│   ├── modelo.ts          # entidades, reglas, demo y línea de tiempo
│   ├── almacen.ts         # localStorage + validación de respaldos
│   ├── formato.ts         # fechas sin zonas horarias
│   ├── imagen.ts          # compresión de fotos
│   ├── camara.ts          # captura con la cámara del dispositivo
│   ├── grabadora.ts       # notas de voz con MediaRecorder (máx. 60 s)
│   ├── recordatorios.ts   # avisos programados + puente nativo
│   ├── ciclo_vida.ts      # libera micrófono y timers al navegar
│   ├── iconos.ts          # íconos SVG en línea
│   ├── pwa.ts             # instalación y service worker
│   ├── ui.ts              # helpers de DOM
│   ├── styles.css
│   └── vistas/            # inicio, registrar, formularios, detalles, ajustes
├── pruebas/               # Vitest (modelo, almacen, grabadora, cámara, rutas, recordatorios)
├── public/                # íconos, manifiesto, robots.txt y service worker
├── macos/                 # app nativa de macOS (WKWebView + Swift)
│   ├── Transi.swift       # ventana, servidor local y menú
│   └── Recordatorios.swift # UNUserNotificationCenter (avisos diarios)
└── docs/capturas/         # capturas del README
```

### Recordatorios programados (app de macOS)

El contenedor nativo registra un puente `recordatorios` en el `WKWebView`. El
frontend calcula la lista pura de avisos (`recordatoriosProgramados`) y la envía;
Swift borra los `transi.recordatorio.*` viejos y agenda cada uno con
`UNCalendarNotificationTrigger(repeats: true)`. Así macOS los entrega aunque
Transi esté cerrada.

El permiso se pide desde una acción del usuario («Activar notificaciones» en
Ajustes, o al guardar un tratamiento con horarios). Para verificar sin esperar
la hora:

```sh
pnpm native:build
dist-mac/Transi.app/Contents/MacOS/Transi --probar-sincronizados
```

El log muestra `[recordatorios] programados N`. Si macOS todavía no autorizó las
notificaciones, el alta falla con «Notifications are not allowed»: hay que
conceder el permiso en Ajustes del Sistema → Notificaciones → Transi.

### Modelo de datos

```ts
type Tratamiento = {
  id: string;
  medicamentos: {
    id: string;
    nombre: string;
    dosis: string;
    frecuencia: string;
    horarios: string[];         // "HH:MM" de recordatorio, vacío si no hay
  }[];
  inicio: string;              // AAAA-MM-DD
  fin: string | null;
  profesional: string | null;
};

type Cambio = {
  id: string;
  fecha: string;               // AAAA-MM-DD
  descripcion: string;
  foto: string | null;         // data URL comprimida
  audio: string | null;        // data URL de la nota de voz
};
```

El estado *en curso* no se guarda: se deriva de la fecha de fin. Una sola fuente
de verdad, menos cosas que puedan quedar inconsistentes.

Los datos de la versión anterior se migran solos al abrir la app: cada
tratamiento viejo se convierte en un tratamiento con un medicamento, sin perder
nada.

## Probarla

```sh
pnpm install
pnpm dev
```

Abrí `http://localhost:5173` y elegí **“Ver la app con datos de ejemplo”**.

```sh
pnpm test     # 121 pruebas
pnpm build    # dist/ listo para publicar
pnpm preview  # servir dist/ en local
```

Cada push corre las pruebas y el build en GitHub Actions
(`.github/workflows/ci.yml`), así un cambio roto no llega a `main`.

### App nativa de macOS

La carpeta `macos/` incluye un envoltorio nativo con `WKWebView` y un servidor
local embebido. No usa Electron ni Tauri: se compila una `.app` real con Swift.

```sh
pnpm native:build   # compila el frontend y arma la app
pnpm native:open    # abre dist-mac/Transi.app
```

La app sirve `dist/` en `127.0.0.1:47615` (puerto fijo para conservar el
`localStorage` entre arranques) y guarda sus datos en
`~/Library/WebKit/com.transi.app`. Solo acepta conexiones desde la misma Mac.

Si el typecheck falla por cambios en curso, `pnpm native:build:fast` empaqueta
sin ejecutar `tsc`.

### Publicar la demo

El repositorio incluye `.github/workflows/paginas.yml`. En GitHub:

1. **Settings → Pages → Source: GitHub Actions**.
2. En **Settings → Secrets and variables → Actions → Variables**, agregá las
   que uses: `VITE_GOOGLE_CLIENT_ID`, `VITE_APPLE_CLIENT_ID`,
   `VITE_APPLE_REDIRECT_URI` y `VITE_FACEBOOK_APP_ID`.
3. Hacé push a `main`.
4. Copiá la URL publicada en la primera línea de este README.

## Capturas

| Inicio | Tratamiento con varios medicamentos | Registrar un cambio |
|---|---|---|
| <img src="docs/capturas/inicio.jpg" width="240" alt="Línea de tiempo con tratamientos en curso"> | <img src="docs/capturas/formulario-tratamiento.jpg" width="240" alt="Formulario de tratamiento con dos medicamentos"> | <img src="docs/capturas/formulario-cambio.jpg" width="240" alt="Formulario de un cambio con foto y nota de voz"> |

| Detalle de un cambio | Ajustes | Primer arranque |
|---|---|---|
| <img src="docs/capturas/detalle-cambio.jpg" width="240" alt="Detalle de un cambio con foto y nota de voz"> | <img src="docs/capturas/ajustes.jpg" width="240" alt="Pantalla de ajustes y datos locales"> | <img src="docs/capturas/bienvenida.jpg" width="240" alt="Pantalla de bienvenida con datos de ejemplo"> |

## Decisiones que vale la pena contar

- **Sin backend como feature, no como limitación.** Al no haber servidor no hay
  base de datos que filtrar, ni sesiones que roten, ni respaldos que se filtren.
  El costo es que los datos viven en un navegador; por eso existen exportar e
  importar.
- **localStorage en vez de IndexedDB.** El modelo entra en unos pocos KB. Las
  fotos se comprimen para que decenas de registros sigan entrando. Si el
  navegador se queda sin espacio, la app avisa en vez de fallar en silencio.
- **TypeScript puro.** Para seis pantallas, un framework agrega más ceremonia
  que ayuda. El router son 40 líneas y cada vista devuelve un nodo del DOM.
- **Datos de ejemplo, no un video.** Quien abre el link puede tocar la app en
  diez segundos, sin registrarse ni cargar nada.

## Privacidad

Transi no envía tus registros de salud a ningún servidor. No usa cookies
propias, analytics ni fuentes externas. Todo lo que cargás se guarda en el
`localStorage` de tu navegador y podés borrar los datos del perfil activo desde
**Ajustes → Empezar de cero**.

Si entrás con Google, Apple o Facebook, el SDK del proveedor se carga desde su
dominio y recibe solo lo necesario para identificarte; **nunca** tus
tratamientos, cambios, fotos ni notas de voz. Sin cuenta no se carga ninguno.

El micrófono solo se activa cuando tocás **Grabar nota** y se apaga al detener
la grabación o salir de la pantalla. Grabar audio requiere HTTPS (o
`localhost`), una restricción de seguridad del navegador.

Esto es una app de registro personal: **no reemplaza un historial clínico ni es
consejo médico**.

---

Hecho con foco en lo simple. Si te sirve la idea, usala, cambiá los textos y
adaptala a lo que necesites.
