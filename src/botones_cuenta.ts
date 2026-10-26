/** Acceso con email y, si están configurados, Google, Apple y Facebook. */

import { montarAccesoEmail } from "./acceso_email";
import { appleConfigurado, cargarApple, entrarConApple } from "./apple";
import { facebookConfigurado, cargarFacebook, entrarConFacebook } from "./facebook";
import { googleConfigurado, montarBotonGoogle } from "./google";
import type { Perfil, Proveedor } from "./perfil";
import { h } from "./ui";

export interface OpcionesProveedores {
  alEntrar: (perfil: Perfil) => void;
  alError: (mensaje: string) => void;
}

type ProveedorSocial = Exclude<Proveedor, "email">;

export function montarProveedores(
  contenedor: HTMLElement,
  opciones: OpcionesProveedores,
): void {
  const email = h("div", { class: "acceso-email-contenedor" });
  montarAccesoEmail(email, { alEntrar: opciones.alEntrar });

  const sociales: HTMLElement[] = [];

  if (googleConfigurado()) {
    const google = h("div", { class: "google-boton" });
    montarBotonGoogle(google, opciones);
    sociales.push(google);
  }

  if (appleConfigurado()) {
    sociales.push(
      botonProveedor("apple", "Continuar con Apple", () => entrarConApple(), opciones),
    );
  }

  if (facebookConfigurado()) {
    sociales.push(
      botonProveedor("facebook", "Continuar con Facebook", () => entrarConFacebook(), opciones),
    );
  }

  const nodos: Node[] = [email];

  if (sociales.length > 0) {
    nodos.push(h("div", { class: "separador-cuentas" }, h("span", {}, "o continuá con")));
    nodos.push(...sociales);
  }

  nodos.push(
    h(
      "p",
      { class: "ayuda" },
      "Las cuentas son opcionales. Guardamos tu nombre y email solo en este dispositivo; " +
        "tus registros de salud no se envían.",
    ),
  );

  if (import.meta.env.DEV && sociales.length === 0) {
    nodos.push(
      h(
        "p",
        { class: "ayuda" },
        "Para probar Google o Apple, configurá tus credenciales en .env. " +
          "La guía está en docs/cuentas.md.",
      ),
    );
  }

  contenedor.replaceChildren(...nodos);

  // Deja los SDK listos para que el clic abra la ventana sin perder el gesto del usuario.
  if (appleConfigurado()) void cargarApple().catch(() => {});
  if (facebookConfigurado()) void cargarFacebook().catch(() => {});
}

function botonProveedor(
  proveedor: ProveedorSocial,
  texto: string,
  accion: () => Promise<Perfil>,
  opciones: OpcionesProveedores,
): HTMLButtonElement {
  const etiqueta = h("span", {}, texto);
  const boton = h(
    "button",
    { class: `btn proveedor ${proveedor}`, type: "button" },
    logo(proveedor),
    etiqueta,
  );

  boton.addEventListener("click", () => {
    void (async () => {
      if (boton.disabled) return;
      boton.disabled = true;
      etiqueta.textContent = "Conectando…";
      try {
        const perfil = await accion();
        opciones.alEntrar(perfil);
      } catch (error) {
        opciones.alError(mensajeError(error));
      } finally {
        if (boton.isConnected) {
          boton.disabled = false;
          etiqueta.textContent = texto;
        }
      }
    })();
  });

  return boton;
}

function mensajeError(error: unknown): string {
  if (error && typeof error === "object" && "error" in error) {
    const codigo = String((error as { error: unknown }).error);
    if (codigo.includes("popup_closed") || codigo.includes("user_cancelled")) {
      return "Cancelaste el ingreso.";
    }
    if (codigo.includes("popup_blocked")) {
      return "El navegador bloqueó la ventana del proveedor. Permití popups y probá de nuevo.";
    }
  }
  return error instanceof Error ? error.message : "No pudimos completar el ingreso.";
}

function logo(proveedor: ProveedorSocial): SVGSVGElement {
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("viewBox", "0 0 24 24");
  svg.setAttribute("aria-hidden", "true");
  svg.setAttribute("focusable", "false");
  svg.setAttribute("class", `logo-proveedor ${proveedor}`);

  if (proveedor === "google") {
    svg.innerHTML = `
      <path fill="#4285F4" d="M23.49 12.27c0-.79-.07-1.54-.19-2.27H12v4.51h6.47a5.54 5.54 0 0 1-2.4 3.58v3h3.86c2.26-2.09 3.56-5.17 3.56-8.82z"/>
      <path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.86-3c-1.08.72-2.45 1.16-4.07 1.16-3.13 0-5.78-2.11-6.73-4.96H1.29v3.09A11.99 11.99 0 0 0 12 24z"/>
      <path fill="#FBBC05" d="M5.27 14.29A7.2 7.2 0 0 1 4.89 12c0-.8.14-1.57.38-2.29V6.62H1.29A11.99 11.99 0 0 0 0 12c0 1.94.46 3.77 1.29 5.38l3.98-3.09z"/>
      <path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.31 0 3.26 2.69 1.29 6.62l3.98 3.09C6.22 6.86 8.87 4.75 12 4.75z"/>`;
  } else if (proveedor === "apple") {
    svg.innerHTML = `<path fill="currentColor" d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>`;
  } else {
    svg.innerHTML = `<path fill="currentColor" d="M22 12a10 10 0 1 0-11.56 9.88v-6.99H7.9V12h2.54V9.8c0-2.5 1.49-3.89 3.77-3.89 1.09 0 2.23.2 2.23.2v2.45h-1.26c-1.24 0-1.63.77-1.63 1.56V12h2.78l-.44 2.89h-2.34v6.99A10 10 0 0 0 22 12z"/>`;
  }

  return svg;
}
