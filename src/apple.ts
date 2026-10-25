/** Identidad con Apple ID (Sign in with Apple JS). */

import { decodificarJwt } from "./jwt";
import type { Perfil } from "./perfil";

export const APPLE_CLIENT_ID = (
  import.meta.env.VITE_APPLE_CLIENT_ID as string | undefined
)?.trim() ?? "";

export const APPLE_REDIRECT_URI =
  (import.meta.env.VITE_APPLE_REDIRECT_URI as string | undefined)?.trim() ||
  (typeof location !== "undefined" ? `${location.origin}${location.pathname}` : "");

const SCRIPT_APPLE =
  "https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js";

let carga: Promise<void> | null = null;
let inicializado = false;

interface NombreApple {
  firstName?: string;
  lastName?: string;
}

export interface RespuestaApple {
  authorization?: { id_token?: string; code?: string; state?: string };
  user?: { name?: NombreApple; email?: string };
}

interface AppleAuth {
  init(configuracion: {
    clientId: string;
    scope?: string;
    redirectURI: string;
    usePopup?: boolean;
    state?: string;
    nonce?: string;
  }): void;
  signIn(): Promise<RespuestaApple>;
}

declare global {
  interface Window {
    AppleID?: { auth: AppleAuth };
  }
}

export function appleConfigurado(): boolean {
  return APPLE_CLIENT_ID.length > 0 && APPLE_REDIRECT_URI.length > 0;
}

export function cargarApple(): Promise<void> {
  if (window.AppleID?.auth) return Promise.resolve();
  if (carga) return carga;

  carga = new Promise((resolver, rechazar) => {
    const script = document.createElement("script");
    script.src = SCRIPT_APPLE;
    script.async = true;
    script.defer = true;
    script.onload = () => resolver();
    script.onerror = () => {
      carga = null;
      rechazar(new Error("No pudimos cargar Apple. Revisá tu conexión."));
    };
    document.head.append(script);
  });
  return carga;
}

export function perfilDesdeApple(
  respuesta: RespuestaApple,
  clientId = APPLE_CLIENT_ID,
  ahora = Date.now(),
): Perfil {
  const token = respuesta.authorization?.id_token;
  if (!token) throw new Error("Apple no devolvió una credencial.");

  const payload = decodificarJwt(token);
  if (typeof payload["sub"] !== "string" || !payload["sub"]) {
    throw new Error("Apple no devolvió un identificador de cuenta.");
  }
  if (typeof payload["email"] !== "string" || !payload["email"]) {
    throw new Error("Apple no devolvió un email.");
  }
  if (clientId && payload["aud"] !== clientId) {
    throw new Error("La cuenta de Apple no corresponde a esta app.");
  }
  if (payload["iss"] !== "https://appleid.apple.com") {
    throw new Error("La respuesta no vino de Apple.");
  }
  if (typeof payload["exp"] === "number" && payload["exp"] * 1000 < ahora) {
    throw new Error("La sesión de Apple venció. Probá de nuevo.");
  }

  const nombre = [respuesta.user?.name?.firstName, respuesta.user?.name?.lastName]
    .map((parte) => (typeof parte === "string" ? parte.trim() : ""))
    .filter(Boolean)
    .join(" ");

  return {
    proveedor: "apple",
    sub: payload["sub"],
    nombre: nombre || payload["email"],
    email: payload["email"],
  };
}

export async function entrarConApple(): Promise<Perfil> {
  if (!appleConfigurado()) {
    throw new Error("Apple no está configurado. Agregá VITE_APPLE_CLIENT_ID y VITE_APPLE_REDIRECT_URI.");
  }

  await cargarApple();
  const apple = window.AppleID?.auth;
  if (!apple) throw new Error("Apple no terminó de cargar.");

  if (!inicializado) {
    apple.init({
      clientId: APPLE_CLIENT_ID,
      scope: "name email",
      redirectURI: APPLE_REDIRECT_URI,
      usePopup: true,
    });
    inicializado = true;
  }

  const respuesta = await apple.signIn();
  return perfilDesdeApple(respuesta);
}
