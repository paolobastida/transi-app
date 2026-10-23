# Transi — frontend Tauri

Reescritura del frontend de Transi con **Tauri 2 + TypeScript puro**, pensada
para ser multiplataforma (desktop primero: macOS; después iOS/Android).

El backend Go (`../backend/`) no cambia: la app sigue siendo **offline-first**
con SQLite local y usa la API solo para identidad y respaldos.

## Cómo correrlo

Requisitos: Rust (`rustup`), Node + pnpm, y Xcode (en macOS).

```sh
cd frontend
pnpm install
pnpm tauri dev
```

Para compilar:

```sh
pnpm tauri build          # .app / .dmg en macOS
pnpm tauri build --debug  # build de desarrollo
```

## Variables de entorno

| Variable | Por defecto | Qué hace |
|---|---|---|
| `TRANSIBASE_URL` | `http://localhost:8080` | URL del backend Go |

En producción **debe** ser `https://…`: por ahí viajan la contraseña, los
tokens y los respaldos con fotos y notas de voz.

## Arquitectura

```
frontend/
├── src/                  # webview: TypeScript puro (sin framework)
│   ├── main.ts           # arranque
│   ├── navegacion.ts     # router mínimo entre vistas
│   ├── api.ts            # invoke() tipado hacia Rust
│   ├── tipos.ts          # contratos con Rust
│   ├── formato.ts        # fechas
│   ├── archivos.ts       # base64 ↔ webview
│   ├── ui.ts             # helpers de DOM y avisos
│   └── vistas/           # login, registro, inicio, timeline, tratamientos, cuenta
└── src-tauri/            # backend Rust
    ├── src/lib.rs        # estado + wiring + comandos
    ├── src/modelo.rs     # entidades y DTOs (serde camelCase)
    ├── src/db.rs         # SQLite (rusqlite): esquema, CRUD, snapshot/restore
    ├── src/api.rs        # auth + respaldos (reqwest) con auto-refresco
    ├── src/comandos.rs   # superficie #[tauri::command]
    └── src/recordatorios.rs  # programador de avisos
```

### Decisiones

- **SQLite en Rust, no en el webview.** La fuente de verdad está en
  `app_data_dir/transi.sqlite3`. El frontend nunca toca la base directamente:
  pasa por comandos tipados.
- **Tokens en el llavero del sistema** (`keyring`), no en `localStorage`.
  El frontend nunca ve el refresh token; el auto-refresco ocurre en Rust.
- **El respaldo mantiene el mismo formato JSON** que la app Flutter, para poder
  restaurar respaldos existentes.
- **Recordatorios:** Tauri solo agenda notificaciones nativas en móvil; en
  desktop el plugin las entrega al instante. Por eso `recordatorios.rs` corre
  un programador propio (cada 30 s) mientras la app está abierta. Cuando se
  porten iOS/Android, ese módulo se cambia por el `schedule` nativo del plugin.

## Estado del port

Implementado (desktop):

- [x] Registro, login y sesión persistente en el llavero.
- [x] Tratamientos: alta (multi-medicamento), edición, borrado lógico, filtros.
- [x] Cambios: foto (archivo), nota de voz (MediaRecorder), detalle, borrado lógico.
- [x] Línea de tiempo unificada con filtros por rango.
- [x] Respaldo y restauración completos (snapshot compatible con Flutter).
- [x] Recordatorios diarios con notificación local (mientras la app corre).
- [x] Tema con la bandera trans.

Móvil:

- [x] Proyecto iOS generado (`src-tauri/gen/apple`).
- [x] Permisos de micrófono/cámara (`src-tauri/Info.ios.plist`).
- [x] Proyecto Android generado (`src-tauri/gen/android`, `compileSdk 37`).
- [x] Llavero multiplataforma: `keyring-core` + store nativo por plataforma
  (Keychain en macOS/iOS, Keystore/SharedPreferences en Android).
- [x] Recordatorios diarios nativos con `Schedule::Interval` (se reagendan al
  crear/editar/desactivar/restaurar tratamientos).
- [x] Probado en **simulador iOS 27**: la app arranca, inicializa SQLite y el
  llavero, y renderiza la pantalla de login.
- [ ] Probar en emulador Android (falta crear un AVD con una system image).
- [ ] Selector de cámara nativo (hoy se usa el archivo del sistema).
- [ ] Firma de la app y distribución.

Artefactos generados:

- iOS: `src-tauri/gen/apple/build/arm64-sim/Transi.app`
- Android: `src-tauri/gen/android/app/build/outputs/apk/universal/debug/app-universal-debug.apk`

### iOS

```sh
cd frontend
pnpm tauri ios dev      # simulador o dispositivo
pnpm tauri ios build    # requiere development team para dispositivo
```

En dispositivo hace falta un *development team* de Apple
(`bundle.iOS.developmentTeam` o `APPLE_DEVELOPMENT_TEAM`). El simulador no
necesita firma, pero sí un **runtime de simulador** acorde al Xcode instalado
(`xcodebuild -downloadPlatform iOS`).

### Android

Requisitos instalados en esta máquina:

- JDK 17: `/opt/homebrew/opt/openjdk@17`
- SDK: `~/Library/Android/sdk` (platform 37.0, build-tools 37.0.0)
- NDK: `27.0.12077973`

```sh
export JAVA_HOME=/opt/homebrew/opt/openjdk@17
export ANDROID_HOME="$HOME/Library/Android/sdk"
export NDK_HOME="$ANDROID_HOME/ndk/$(ls -1 "$ANDROID_HOME/ndk" | tail -1)"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

cd frontend
pnpm tauri android dev
pnpm tauri android build --apk
```

> El contexto de Android que necesita el llavero nativo lo inicializa `tao`
> (base de Tauri), así que `keyring-core` funciona sin glue code extra.


## Verificación

```sh
pnpm build          # tsc + vite
cargo check         # en src-tauri/
```
