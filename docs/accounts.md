# Accounts: email, Google, Apple and Facebook

The account in Transi is **optional**: without any credentials the app works
just the same, with data on the device.

**Email access works without configuring anything.** Google, Apple and Facebook
are optional and need their own credentials for their buttons to appear.

There is no backend: identity is resolved in the browser and treatments,
changes, photos and voice notes are **never** sent to the providers.

## Email (works without configuring anything)

On the entry screen, fill in **Email** and, if you want, your **Name**.
Transi creates a local profile with that email or recovers the one that already
exists on this device.

- There is no password, email verification or server.
- The email only separates data by profile on this device.
- If you already used the same email here, you return to your records. If you
  type a new one, an empty space is created (your other profiles remain saved).
- It is not a security control: someone with your unlocked device can open the
  app. To protect yourself, use your phone's lock and export backups.

## Before configuring Google, Apple or Facebook

1. Copy the example file:

   ```sh
   cp .env.example .env
   ```

2. Every time you change a `VITE_*` variable, restart the server:

   ```sh
   pnpm dev
   ```

3. For the published demo, load the same variables in GitHub:
   **Settings → Secrets and variables → Actions → Variables**. The workflow
   `.github/workflows/paginas.yml` passes them to the build.

---

## Google

1. Go to [Google Cloud Console](https://console.cloud.google.com/) and create a
   project (or choose one).
2. **APIs and services → OAuth consent screen**:
   - User type: **External**.
   - Fill in app name, support email and contact.
   - Scopes: `openid`, `email` and `profile` are enough.
   - While in **Testing** mode, add your account under **Test users**.
3. **APIs and services → Credentials → Create credentials → OAuth client ID**:
   - Type: **Web application**.
   - **Authorized JavaScript origins**:
     - `http://localhost:5173`
     - `https://paolobastida.github.io`
4. Copy the **Client ID** (ends in `.apps.googleusercontent.com`) into `.env`:

   ```sh
   VITE_GOOGLE_CLIENT_ID=1234567890-abc.apps.googleusercontent.com
   ```

5. Restart `pnpm dev`. The Google button becomes the official Google Identity
   Services button.

> For anyone to enter (not just your test users), publish the consent screen.
> Google may request review if you show your brand.

---

## Apple ID (Sign in with Apple)

Apple is the most bureaucratic: it requires the **Apple Developer Program**
(paid account), an HTTPS domain and verification of that domain.

1. In [developer.apple.com](https://developer.apple.com/account/) go to
   **Certificates, Identifiers & Profiles → Identifiers**.
2. Create an **App ID** (if you don't have one) and enable **Sign in with
   Apple**.
3. Create a **Services ID**:
   - Identifier: for example `com.yourname.transi.web`.
   - Enable **Sign in with Apple** and tap **Configure**.
   - **Primary App ID**: the App ID from step 2.
   - **Domains and Subdomains**: your domain, without protocol or path
     (e.g. `transi.yourdomain.com`).
   - **Return URLs**: the exact URL where the popup returns, for example
     `https://transi.yourdomain.com/`.
4. Apple gives you an association file. Publish it at the **root of the
   domain**:

   ```
   https://transi.yourdomain.com/.well-known/apple-developer-domain-association.txt
   ```

   In this project, put it in `public/.well-known/` and Vite copies it to
   `dist/`.
5. Fill in `.env` with the **Services ID** (not the App ID) and the Return URL:

   ```sh
   VITE_APPLE_CLIENT_ID=com.yourname.transi.web
   VITE_APPLE_REDIRECT_URI=https://transi.yourdomain.com/
   ```

6. Restart `pnpm dev` or redeploy.

> **Apple does not work on `localhost`.** You need a real HTTPS domain (or an
> HTTPS tunnel) and the `.well-known` file at the root of that domain. If you
> use GitHub Pages with `https://paolobastida.github.io/transi-app/`, the domain is
> `paolobastida.github.io` and the file must be in the `paolobastida.github.io`
> repo, not in the `/transi-app/` subdirectory. To avoid trouble, use your own
> domain.

---

## Facebook

1. Go to [Meta for Developers](https://developers.facebook.com/apps/) and create
   an app of type **Consumer**.
2. Add the product **Facebook Login → Web**.
3. In **Settings → Basic**:
   - Copy the **App ID**.
   - **App domains**: `localhost` and `paolobastida.github.io`.
   - **Site URL**: `https://paolobastida.github.io/transi-app/`.
4. In **Facebook Login → Settings**:
   - **Valid OAuth Redirect URIs**:
     - `http://localhost:5173/`
     - `https://paolobastida.github.io/transi-app/`
5. Fill in `.env`:

   ```sh
   VITE_FACEBOOK_APP_ID=123456789012345
   ```

6. In **App mode**, use **Development** to test with your test accounts. For
   anyone to enter, switch the app to **Live** (Meta requires privacy policy,
   data deletion URL, etc.).

> Facebook's SDK loads from `connect.facebook.net`; some ad blockers stop it.
> If the button does nothing, try without a blocker.

---

## Check that it worked

1. Open `http://localhost:5173` in a private window. You should see the
   **"Enter or create your space"** screen.
2. Try **email** access: fill in an email and, if you want, your name. It
   should enter without asking for a password and create the local profile.
3. If you configured providers, test them:
   - **Google**: opens the account picker.
   - **Apple**: opens the Apple popup; the first time it shares name and email.
   - **Facebook**: opens the permissions popup and requests `public_profile`
     and `email`.
4. On entry:
   - Your initials avatar appears in the header.
   - Data counters are at zero (it's another profile).
   - If there were records without an account, Transi offers to move them to
     the account.
5. Log out from **Settings → Your account**. You return to the anonymous
   profile and your previous records are still there.
6. Reload: the session stays saved in `localStorage`.

## If something fails

| Error | What to check |
|---|---|
| `redirect_uri_mismatch` (Google) | The origin must match **exactly** what was declared, including `http/https` and the port. Wait a few minutes after saving. |
| `invalid_client` or `invalid_request` (Apple) | You are using the App ID instead of the **Services ID**, the Return URL doesn't match or the `.well-known` file isn't at the domain root. |
| "Blocked URL" (Facebook) | The redirect URL isn't declared or the app is in Development mode with a non-test account. |
| The popup doesn't open | Allow popups for the site and disable blockers. |
| Says "not configured" | Missing variable in `.env` or you didn't restart `pnpm dev`; on Pages, missing Actions variables and a new deploy. |

## Security

- **Email access is local and passwordless.** It doesn't verify that the email
  is yours or protect data from someone else with the device. It serves to
  separate profiles, not as access control.
- Google and Apple deliver an **ID token**; the app validates `aud`, `iss` and
  `exp` in the browser.
- **The signature is not verified**: there is no backend to do it. It's a
  local identity to separate profiles, not a security access control.
- If Transi ever stores sensitive data on a server, that server must validate
  the token before accepting any operation.
