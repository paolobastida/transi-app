/** Acceso local con email: crea o recupera un perfil en este dispositivo. */

import { icono } from "./iconos";
import type { Perfil } from "./perfil";
import { h } from "./ui";
import { campo } from "./vistas/comunes";

export interface OpcionesAccesoEmail {
  alEntrar: (perfil: Perfil) => void;
}

export function emailValido(valor: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(valor.trim());
}

/** Convierte un email en un perfil local. El email es la identidad estable. */
export function perfilDesdeEmail(email: string, nombre = ""): Perfil | null {
  const limpio = email.trim().toLowerCase();
  if (!emailValido(limpio)) return null;

  const nombreLimpio = nombre.trim();
  return {
    proveedor: "email",
    sub: limpio,
    nombre: nombreLimpio || limpio.split("@")[0] || "Sin nombre",
    email: limpio,
  };
}

export function montarAccesoEmail(
  contenedor: HTMLElement,
  opciones: OpcionesAccesoEmail,
): void {
  const nombre = h("input", {
    type: "text",
    name: "nombre",
    autocomplete: "name",
    placeholder: "Tu nombre",
    maxlength: "80",
  });

  const email = h("input", {
    type: "email",
    name: "email",
    autocomplete: "email",
    inputmode: "email",
    autocapitalize: "none",
    spellcheck: "false",
    placeholder: "vos@ejemplo.com",
    required: true,
  });

  const error = h(
    "p",
    { class: "ayuda error-campo oculto", id: "error-email", role: "alert" },
    "",
  );
  email.setAttribute("aria-describedby", "error-email");

  const formulario = h(
    "form",
    {
      class: "acceso-email",
      novalidate: "true",
      onSubmit: (evento: SubmitEvent) => {
        evento.preventDefault();
        const perfil = perfilDesdeEmail(email.value, nombre.value);
        if (!perfil) {
          error.textContent = "Escribí un email válido, por ejemplo vos@ejemplo.com.";
          error.classList.remove("oculto");
          email.setAttribute("aria-invalid", "true");
          email.focus();
          return;
        }

        error.classList.add("oculto");
        email.removeAttribute("aria-invalid");
        opciones.alEntrar(perfil);
      },
    },
    campo("Email", email),
    campo("Nombre", nombre, "Si lo dejás vacío, usamos la primera parte de tu email.", true),
    error,
    h(
      "button",
      { class: "btn primario", type: "submit" },
      icono("email"),
      "Continuar con email",
    ),
    h(
      "p",
      { class: "ayuda" },
      "Si ya usaste este email en este dispositivo, volvés a tus datos. " +
        "No hay contraseña ni servidor: la cuenta vive solo acá.",
    ),
  );

  email.addEventListener("input", () => {
    error.classList.add("oculto");
    email.removeAttribute("aria-invalid");
  });

  contenedor.replaceChildren(formulario);
}
