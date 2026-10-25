/** Tipos mínimos de Google Identity Services (cargado solo al iniciar sesión).
 *
 *  Va dentro de `declare global` porque el tsconfig usa `moduleDetection: "force"`,
 *  que convierte todo archivo en módulo: un `interface Window` a secas quedaría
 *  local al módulo y no se fusionaría con el global.
 *
 *  El nombre no puede ser `google.d.ts`: chocaría con `google.ts` y TypeScript lo
 *  trataría como el hermano declarativo del módulo, ignorándolo como ambiental. */

export {};

declare global {
  interface GoogleCredentialResponse {
    credential: string;
    select_by?: string;
  }

  interface GoogleIdConfiguration {
    client_id: string;
    callback: (respuesta: GoogleCredentialResponse) => void;
    auto_select?: boolean;
    cancel_on_tap_outside?: boolean;
    ux_mode?: "popup" | "redirect";
  }

  interface GoogleButtonOptions {
    type?: "standard" | "icon";
    theme?: "outline" | "filled_blue" | "filled_black";
    size?: "large" | "medium" | "small";
    text?: "signin_with" | "signup_with" | "continue_with" | "signin";
    shape?: "rectangular" | "pill" | "circle" | "square";
    logo_alignment?: "left" | "center";
    width?: number;
    locale?: string;
  }

  interface GoogleAccountsId {
    initialize(configuracion: GoogleIdConfiguration): void;
    renderButton(contenedor: HTMLElement, opciones: GoogleButtonOptions): void;
  }

  interface Window {
    google?: {
      accounts?: {
        id?: GoogleAccountsId;
      };
    };
  }
}
