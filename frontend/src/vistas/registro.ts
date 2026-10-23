import { api } from "../api";
import { irAInicio, irALogin } from "../navegacion";
import { aviso, h } from "../ui";

export function vistaRegistro(): HTMLElement {
  const email = h("input", {
    type: "email",
    required: "true",
    autocomplete: "email",
    placeholder: "tina@ejemplo.com",
  });
  const clave = h("input", {
    type: "password",
    required: "true",
    autocomplete: "new-password",
    placeholder: "Al menos 8 caracteres",
  });
  const repetida = h("input", {
    type: "password",
    required: "true",
    autocomplete: "new-password",
    placeholder: "Repetí la contraseña",
  });
  const boton = h("button", { type: "submit", class: "btn primario" }, "Crear cuenta");

  const forma = h(
    "form",
    { class: "tarjeta auth" },
    h(
      "div",
      { class: "marca-auth" },
      h("span", { class: "logo" }),
      h("h1", {}, "Crear cuenta"),
    ),
    h("p", { class: "sub" }, "Tus datos de salud quedan en tu dispositivo."),
    h("label", { class: "campo" }, h("span", {}, "Email"), email),
    h("label", { class: "campo" }, h("span", {}, "Contraseña"), clave),
    h("label", { class: "campo" }, h("span", {}, "Repetir contraseña"), repetida),
    boton,
    h(
      "button",
      { type: "button", class: "enlace", onClick: () => irALogin() },
      "Ya tengo cuenta",
    ),
  );

  forma.addEventListener("submit", async (evento) => {
    evento.preventDefault();
    if (clave.value.length < 8) {
      aviso("La contraseña necesita al menos 8 caracteres", true);
      return;
    }
    if (clave.value !== repetida.value) {
      aviso("Las contraseñas no coinciden", true);
      return;
    }
    boton.setAttribute("disabled", "true");
    try {
      await api.registrar(email.value.trim(), clave.value);
      const usuario = await api.entrar(email.value.trim(), clave.value);
      irAInicio(usuario);
    } catch (error) {
      aviso(String(error), true);
    } finally {
      boton.removeAttribute("disabled");
    }
  });

  return h("div", { class: "pantalla-auth" }, forma);
}
