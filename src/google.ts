/** Identidad con Google Identity Services (cargado solo al iniciar sesión). */

import { decodificarJwt } from "./jwt";
import type { Perfil } from "./perfil";
import { h } from "./ui";

export const GOOGLE_CLIENT_ID = (
  import.meta.env.VITE_GOOGLE_CLIENT_ID as string | undefined
)?.trim() ?? "";

const SCRIPT_GOOGLE = "https://accounts.google.com/gsi/client";

let carga: Promise<void> | null = null;

export function googleConfigurado(): boolean {
  return GOOGLE_CLIENT_ID.length > 0;
}

/** Decodifica y valida los claims del ID token. La firma la garantiza Google; no hay backend. */
export function perfilDesdeCredencial(
  credential: string,
  clientId = GOOGLE_CLIENT_ID,
  ahora = Date.now(),
): Perfil {
  const payload = decodificarJwt(credential);

  if (typeof payload["sub"] !== "string" || !payload["sub"]) {
    throw new Error("Google no devolvió un identificador de cuenta.");
  }
  if (typeof payload["email"] !== "string" || !payload["email"]) {
    throw new Error("Google no devolvió un email.");
  }
  if (clientId && payload["aud"] !== clientId) {
    throw new Error("La cuenta de Google no corresponde a esta app.");
  }
  if (payload["iss"] !== "accounts.google.com" && payload["iss"] !== "https://accounts.google.com") {
    throw new Error("La respuesta no vino de Google.");
  }
  if (typeof payload["exp"] === "number" && payload["exp"] * 1000 < ahora) {
    throw new Error("La sesión de Google venció. Probá de nuevo.");
  }

  const nombre =
    (typeof payload["name"] === "string" && payload["name"]) ||
    (typeof payload["given_name"] === "string" && payload["given_name"]) ||
    payload["email"];

  return { proveedor: "google", sub: payload["sub"], nombre, email: payload["email"] };
}

export function cargarGoogle(): Promise<void> {
  if (window.google?.accounts?.id) return Promise.resolve();
  if (carga) return carga;

  carga = new Promise((resolver, rechazar) => {
    const script = document.createElement("script");
    script.src = SCRIPT_GOOGLE;
    script.async = true;
    script.defer = true;
    script.onload = () => resolver();
    script.onerror = () => {
      carga = null;
      rechazar(new Error("No pudimos cargar Google. Revisá tu conexión."));
    };
    document.head.append(script);
  });
  return carga;
}

export interface OpcionesBotonGoogle {
  alEntrar: (perfil: Perfil) => void;
  alError: (mensaje: string) => void;
}

/** Dibuja el botón oficial de Google o una nota si falta configurar el Client ID. */
export function montarBotonGoogle(contenedor: HTMLElement, opciones: OpcionesBotonGoogle): void {
  if (!googleConfigurado()) {
    contenedor.replaceChildren(
      h(
        "div",
        { class: "google-config" },
        h("strong", {}, "Inicio de sesión no disponible"),
        h(
          "p",
          { class: "ayuda" },
          import.meta.env.DEV
            ? "Faltan las credenciales de Google o Facebook para probar el inicio de sesión. La app funciona igual sin cuenta."
            : "Por ahora no podés iniciar sesión con una cuenta en esta versión. Todo funciona igual sin cuenta.",
        ),
      ),
    );
    return;
  }

  contenedor.replaceChildren(h("p", { class: "ayuda" }, "Cargando Google…"));

  void cargarGoogle()
    .then(() => {
      if (!contenedor.isConnected) return;
      const id = window.google?.accounts?.id;
      if (!id) throw new Error("Google no terminó de cargar.");

      id.initialize({
        client_id: GOOGLE_CLIENT_ID,
        auto_select: false,
        cancel_on_tap_outside: true,
        callback: (respuesta) => {
          try {
            opciones.alEntrar(perfilDesdeCredencial(respuesta.credential));
          } catch (error) {
            opciones.alError(
              error instanceof Error ? error.message : "No pudimos validar la cuenta de Google.",
            );
          }
        },
      });

      contenedor.replaceChildren();
      id.renderButton(contenedor, {
        type: "standard",
        theme: "outline",
        size: "large",
        text: "continue_with",
        shape: "pill",
        logo_alignment: "left",
        width: 280,
        locale: "es",
      });
    })
    .catch((error: unknown) => {
      if (!contenedor.isConnected) return;
      contenedor.replaceChildren(
        h(
          "button",
          {
            class: "btn secundario",
            type: "button",
            onClick: () => montarBotonGoogle(contenedor, opciones),
          },
          "Reintentar con Google",
        ),
        h(
          "p",
          { class: "ayuda" },
          error instanceof Error ? error.message : "No pudimos cargar Google.",
        ),
      );
    });
}
