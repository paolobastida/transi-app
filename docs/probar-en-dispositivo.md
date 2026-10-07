# Transi — Probar en un dispositivo real

> Cómo correr la app en un teléfono de verdad, hablando con el servidor que
> corre en tu computadora.

El camino fácil es **Android**. iOS también se puede, pero requiere Xcode
completo y una cuenta de desarrollador de Apple para firmar.

---

## 0. Antes que nada: herramientas

En una computadora sin el entorno instalado, `flutter doctor` avisa:

- **Android:** hace falta el **SDK de Android** (viene con Android Studio).
- **iOS:** hace falta **Xcode** completo.

```sh
flutter doctor
```

Instalá lo que falte y volvé a correr `flutter doctor` hasta que diga ✓.

---

## 1. Averiguar la IP de tu computadora

El teléfono no puede usar `localhost` (eso es el teléfono mismo). Necesitás la
**IP de tu computadora en la red WiFi**:

```sh
# macOS (WiFi)
ipconfig getifaddr en0

# Linux
hostname -I
```

Ejemplo: `192.168.0.15`.

---

## 2. Arrancar el servidor escuchando en la red

El backend ya escucha en todas las interfaces (`:8080`). Desde la carpeta del
backend:

```sh
cd backend
make run
```

- Asegurate de que la **base esté encendida**: `docker compose up -d --wait`.
- En macOS puede aparecer un aviso de firewall: **permitir conexiones entrantes**.
- Probá desde el propio teléfono, en el navegador: `http://192.168.0.15:8080/salud`
  → debería decir `{"estado":"ok"}`. Si no, ver la sección de problemas.

---

## 3. Conectar el teléfono (Android)

1. En el teléfono: **Ajustes → Acerca del teléfono → tocar 7 veces "Número de
   compilación"** para activar las opciones de desarrollador.
2. **Ajustes → Opciones de desarrollador → Depuración por USB** (activar).
3. Conectar por cable USB. El teléfono pedirá **autorizar la depuración**: aceptar.
4. Verificar:

   ```sh
   flutter devices
   ```

   Debe aparecer tu teléfono (por ejemplo `Pixel 7`).

---

## 4. Correr la app apuntando al servidor

```sh
cd app
flutter run --dart-define=API_BASE_URL=http://192.168.0.15:8080
```

Cambiá `192.168.0.15` por tu IP. La app se instala y arranca en el teléfono.

**Lo primero que vas a probar:**

1. Registrarte (necesita red).
2. Crear un profesional y un tratamiento (esto ya es local).
3. **Registrar un cambio**: va a pedir permiso de **cámara** y **micrófono**;
   aceptá y sacá una foto / grabá una voz.
4. Ver la **línea de tiempo**.
5. Ícono de nube → **Respaldar ahora**.
6. **Modo avión**: activalo y seguí usando la app (todo lo local funciona).
   Volvé a conectar para restaurar.

---

## 5. Alternativa: instalar un APK sin cable

```sh
cd app
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.0.15:8080
```

El archivo queda en `app/build/app/outputs/flutter-apk/app-debug.apk`. Copialo al
teléfono e instalalo (hay que permitir "instalar apps de origen desconocido").

---

## 6. iOS (iPhone/iPad)

1. Instalar **Xcode** completo y aceptar la licencia.
2. `sudo xcodebuild -runFirstLaunch`.
3. Abrir el proyecto en Xcode y configurar un **equipo de firma** (Signing &
   Capabilities → Team) con tu Apple ID.
4. En el iPhone: confiar en el desarrollador (Ajustes → General → VPN y
   administración de dispositivos).
5. Correr:

   ```sh
   cd app
   flutter run --dart-define=API_BASE_URL=http://192.168.0.15:8080
   ```

---

## 7. Problemas frecuentes

| Síntoma | Causa probable | Solución |
|---|---|---|
| El teléfono no aparece en `flutter devices` | SDK/depuración USB | Instalar SDK; activar depuración USB; autorizar el equipo |
| La app dice "No se pudo conectar" | IP equivocada o red distinta | Verificar que el teléfono y la computadora estén en el **mismo WiFi**; usar la IP correcta |
| `http://…/salud` no abre en el teléfono | Firewall o aislamiento de red | Permitir el puerto 8080; desactivar "aislamiento de clientes" en el router |
| La IP cambió | DHCP | Volver a averiguar la IP, o reservarla en el router |
| Error de "cleartext not permitted" | HTTP en Android/iOS | Ya resuelto para **debug** (ver `AndroidManifest.xml` de debug y `Info.plist`) |
| No pide permiso de cámara/micrófono | Permisos denegados antes | Ajustes de la app → Permisos → activar |

---

## 8. Recordatorio de seguridad

- `--dart-define=API_BASE_URL=http://…` es **solo para desarrollo** (HTTP, red
  local).
- En producción, la app apunta a `https://tu-dominio` (ver
  [`despliegue.md`](despliegue.md)) y no necesita los permisos de red local.
