/** Identidad con Facebook Login (SDK de JavaScript). */

import type { Perfil } from "./perfil";

export const FACEBOOK_APP_ID = (
  import.meta.env.VITE_FACEBOOK_APP_ID as string | undefined
)?.trim() ?? "";

const VERSION_FACEBOOK = "v21.0";
const SCRIPT_FACEBOOK = "https://connect.facebook.net/es_LA/sdk.js";

let carga: Promise<void> | null = null;

export interface RespuestaLoginFacebook {
  status: "connected" | "not_authorized" | "unknown";
  authResponse?: {
    accessToken: string;
    userID: string;
    expiresIn: number;
    signedRequest: string;
  };
}

export interface PerfilFacebookApi {
  id?: string;
  name?: string;
  email?: string;
  error?: { message?: string };
}

interface FacebookSdk {
  init(opciones: { appId: string; cookie?: boolean; xfbml?: boolean; version: string }): void;
  login(
    callback: (respuesta: RespuestaLoginFacebook) => void,
    opciones?: { scope: string },
  ): void;
  api(
    ruta: string,
    parametros: Record<string, string>,
    callback: (respuesta: PerfilFacebookApi) => void,
  ): void;
}

declare global {
  interface Window {
    FB?: FacebookSdk;
  }
}

export function facebookConfigurado(): boolean {
  return FACEBOOK_APP_ID.length > 0;
}

export function cargarFacebook(): Promise<void> {
  if (window.FB) return Promise.resolve();
  if (carga) return carga;

  carga = new Promise((resolver, rechazar) => {
    const script = document.createElement("script");
    script.src = SCRIPT_FACEBOOK;
    script.async = true;
    script.defer = true;
    script.onload = () => {
      const fb = window.FB;
      if (!fb) {
        rechazar(new Error("Facebook no terminó de cargar."));
        return;
      }
      fb.init({
        appId: FACEBOOK_APP_ID,
        cookie: false,
        xfbml: false,
        version: VERSION_FACEBOOK,
      });
      resolver();
    };
    script.onerror = () => {
      carga = null;
      rechazar(new Error("No pudimos cargar Facebook. Revisá tu conexión."));
    };
    document.head.append(script);
  });
  return carga;
}

export async function entrarConFacebook(): Promise<Perfil> {
  if (!facebookConfigurado()) {
    throw new Error("Facebook no está configurado. Agregá VITE_FACEBOOK_APP_ID.");
  }

  await cargarFacebook();
  const fb = window.FB;
  if (!fb) throw new Error("Facebook no terminó de cargar.");

  await new Promise<RespuestaLoginFacebook>((resolver, rechazar) => {
    fb.login(
      (respuesta) => {
        if (respuesta.status === "connected" && respuesta.authResponse) {
          resolver(respuesta);
        } else {
          rechazar(new Error("No se completó el ingreso con Facebook."));
        }
      },
      { scope: "public_profile,email" },
    );
  });

  const perfil = await new Promise<PerfilFacebookApi>((resolver, rechazar) => {
    fb.api(
      "/me",
      { fields: "id,name,email" },
      (respuesta) => {
        if (!respuesta || respuesta.error || !respuesta.id) {
          rechazar(new Error("Facebook no devolvió tu perfil."));
          return;
        }
        resolver(respuesta);
      },
    );
  });

  if (!perfil.id) {
    throw new Error("Facebook no devolvió tu identificador. Probá de nuevo.");
  }
  if (!perfil.email) {
    throw new Error("Facebook no compartió tu email. Probá con otra cuenta o con Google.");
  }

  return {
    proveedor: "facebook",
    sub: perfil.id,
    nombre: perfil.name || perfil.email,
    email: perfil.email,
  };
}
