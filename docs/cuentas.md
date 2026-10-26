# Cuentas: email, Google, Apple y Facebook

La cuenta en Transi es **opcional**: sin ninguna credencial la app funciona
igual, con los datos en el dispositivo.

El acceso con **email funciona sin configurar nada**. Google, Apple y Facebook
son opcionales y necesitan credenciales propias para que sus botones aparezcan.

No hay backend: la identidad se resuelve en el navegador y **nunca** se envían
tratamientos, cambios, fotos ni notas de voz a los proveedores.

## Email (funciona sin configurar nada)

En la pantalla de entrada, completá **Email** y, si querés, tu **Nombre**.
Transi crea un perfil local con ese email o recupera el que ya existe en este
dispositivo.

- No hay contraseña, verificación por correo ni servidor.
- El email solo separa los datos por perfil en este dispositivo.
- Si ya usaste el mismo email acá, volvés a tus registros. Si escribís uno
  nuevo, se crea un espacio vacío (tus otros perfiles siguen guardados).
- No es un control de seguridad: alguien con tu dispositivo desbloqueado puede
  abrir la app. Para protegerte, usá el bloqueo del teléfono y exportá respaldos.

## Antes de configurar Google, Apple o Facebook

1. Copiá el archivo de ejemplo:

   ```sh
   cp .env.example .env
   ```

2. Cada vez que cambies una variable `VITE_*`, reiniciá el servidor:

   ```sh
   pnpm dev
   ```

3. Para la demo publicada, cargá las mismas variables en GitHub:
   **Settings → Secrets and variables → Actions → Variables**. El workflow
   `.github/workflows/paginas.yml` las pasa al build.

---

## Google

1. Entrá a [Google Cloud Console](https://console.cloud.google.com/) y creá un
   proyecto (o elegí uno).
2. **APIs y servicios → Pantalla de consentimiento de OAuth**:
   - Tipo de usuario: **Externo**.
   - Completá nombre de la app, email de soporte y contacto.
   - Scopes: alcanzan `openid`, `email` y `profile`.
   - Mientras esté en modo **Prueba**, agregá tu cuenta en **Usuarios de prueba**.
3. **APIs y servicios → Credenciales → Crear credenciales → ID de cliente de
   OAuth**:
   - Tipo: **Aplicación web**.
   - **Orígenes de JavaScript autorizados**:
     - `http://localhost:5173`
     - `https://paolobastida.github.io`
4. Copiá el **Client ID** (termina en `.apps.googleusercontent.com`) en `.env`:

   ```sh
   VITE_GOOGLE_CLIENT_ID=1234567890-abc.apps.googleusercontent.com
   ```

5. Reiniciá `pnpm dev`. El botón de Google pasa a ser el botón oficial de
   Google Identity Services.

> Para que entre cualquier persona (no solo tus usuarios de prueba), publicá la
> pantalla de consentimiento. Google puede pedir revisión si mostrás la marca.

---

## Apple ID (Sign in with Apple)

Apple es el más burocrático: requiere **Apple Developer Program** (cuenta paga),
un dominio HTTPS y verificar ese dominio.

1. En [developer.apple.com](https://developer.apple.com/account/) andá a
   **Certificates, Identifiers & Profiles → Identifiers**.
2. Creá un **App ID** (si no tenés) y habilitá **Sign in with Apple**.
3. Creá un **Services ID**:
   - Identifier: por ejemplo `com.tunombre.transi.web`.
   - Habilitá **Sign in with Apple** y tocá **Configure**.
   - **Primary App ID**: el App ID del paso 2.
   - **Domains and Subdomains**: tu dominio, sin protocolo ni path
     (ej. `transi.tudominio.com`).
   - **Return URLs**: la URL exacta donde vuelve el popup, por ejemplo
     `https://transi.tudominio.com/`.
4. Apple te da un archivo de asociación. Publicalo en la **raíz del dominio**:

   ```
   https://transi.tudominio.com/.well-known/apple-developer-domain-association.txt
   ```

   En este proyecto, ponelo en `public/.well-known/` y Vite lo copia a `dist/`.
5. Completá `.env` con el **Services ID** (no el App ID) y la Return URL:

   ```sh
   VITE_APPLE_CLIENT_ID=com.tunombre.transi.web
   VITE_APPLE_REDIRECT_URI=https://transi.tudominio.com/
   ```

6. Reiniciá `pnpm dev` o volvé a desplegar.

> **Apple no funciona en `localhost`.** Necesitás un dominio HTTPS real (o un
> túnel HTTPS) y que el archivo `.well-known` esté en la raíz de ese dominio.
> Si usás GitHub Pages con `https://paolobastida.github.io/transi-app/`, el dominio es
> `paolobastida.github.io` y el archivo tiene que estar en el repo
> `paolobastida.github.io`, no en el subdirectorio `/transi-app/`. Para evitar líos,
> usá un dominio propio.

---

## Facebook

1. Entrá a [Meta for Developers](https://developers.facebook.com/apps/) y creá
   una app de tipo **Consumidor**.
2. Agregá el producto **Facebook Login → Web**.
3. En **Configuración → Básica**:
   - Copiá el **ID de la app**.
   - **Dominios de la app**: `localhost` y `paolobastida.github.io`.
   - **URL del sitio**: `https://paolobastida.github.io/transi-app/`.
4. En **Facebook Login → Configuración**:
   - **URI de redireccionamiento de OAuth válidos**:
     - `http://localhost:5173/`
     - `https://paolobastida.github.io/transi-app/`
5. Completá `.env`:

   ```sh
   VITE_FACEBOOK_APP_ID=123456789012345
   ```

6. En **Modo de la app**, usá **Desarrollo** para probar con tus cuentas de
   prueba. Para que entre cualquier persona, pasá la app a **Live** (Meta pide
   política de privacidad, URL de eliminación de datos, etc.).

> El SDK de Facebook se carga desde `connect.facebook.net`; algunos bloqueadores
> de anuncios lo frenan. Si el botón no abre nada, probá sin bloqueador.

---

## Probar que quedó bien

1. Abrí `http://localhost:5173` en una ventana privada. Debería aparecer la
   pantalla **“Entrá o creá tu espacio”**.
2. Probá el acceso con **email**: completá un email y, si querés, tu nombre.
   Debería entrar sin pedir contraseña y crear el perfil local.
3. Si configuraste proveedores, probalos:
   - **Google**: abre el selector de cuentas.
   - **Apple**: abre el popup de Apple; la primera vez comparte nombre y email.
   - **Facebook**: abre el popup de permisos y pide `public_profile` y `email`.
4. Al entrar:
   - Aparece el avatar con tus iniciales en la cabecera.
   - Los contadores de datos quedan en cero (es otro perfil).
   - Si había registros sin cuenta, Transi ofrece **llevarlos a la cuenta**.
5. Cerrá sesión desde **Ajustes → Tu cuenta**. Volvés al perfil anónimo y tus
   registros de antes siguen ahí.
6. Recargá: la sesión se mantiene guardada en el `localStorage`.

## Si algo falla

| Error | Qué revisar |
|---|---|
| `redirect_uri_mismatch` (Google) | El origen debe coincidir **exacto** con el declarado, incluyendo `http/https` y el puerto. Esperá unos minutos después de guardar. |
| `invalid_client` o `invalid_request` (Apple) | Estás usando el App ID en vez del **Services ID**, la Return URL no coincide o el archivo `.well-known` no está en la raíz del dominio. |
| “URL bloqueada” (Facebook) | La URL de redireccionamiento no está declarada o la app está en modo Desarrollo con una cuenta que no es de prueba. |
| El popup no abre | Permití ventanas emergentes para el sitio y desactivá bloqueadores. |
| Dice “no está configurado” | Falta la variable en `.env` o no reiniciaste `pnpm dev`; en Pages, faltan las variables de Actions y un nuevo deploy. |

## Seguridad

- El acceso con **email es local y sin contraseña**. No verifica que el email
  sea tuyo ni protege los datos frente a otra persona con el dispositivo.
  Sirve para separar perfiles, no como control de acceso.
- Google y Apple entregan un **ID token**; la app valida `aud`, `iss` y `exp`
  en el navegador.
- **No se verifica la firma** del token: no hay backend que lo haga. Es una
  identidad local para separar perfiles, no un control de acceso de seguridad.
- Si Transi algún día guarda datos sensibles en un servidor, ese servidor debe
  validar el token antes de aceptar cualquier operación.
