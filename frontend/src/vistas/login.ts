import { api } from "../api";
import { irAInicio, irARegistro } from "../navegacion";
import { aviso, h } from "../ui";

export function vistaLogin(): HTMLElement {
  const email = h("input", {
    type: "email",
    required: "true",
    autocomplete: "email",
    placeholder: "tina@ejemplo.com",
  });
  const clave = h("input", {
    type: "password",
    required: "true",
    autocomplete: "current-password",
    placeholder: "Tu contraseña",
  });
  const boton = h("button", { type: "submit", class: "btn primario" }, "Entrar");

  const forma = h(
    "form",
    { class: "tarjeta auth" },
    h(
      "div",
      { class: "marca-auth" },
      h("span", { class: "logo" }),
      h("h1", {}, "Transi"),
    ),
    h("p", { class: "sub" }, "Tus tratamientos y tu evolución, en un solo lugar."),
    h("label", { class: "campo" }, h("span", {}, "Email"), email),
    h("label", { class: "campo" }, h("span", {}, "Contraseña"), clave),
    boton,
    h(
      "button",
      { type: "button", class: "enlace", onClick: () => irARegistro() },
      "Crear una cuenta",
    ),
  );

  forma.addEventListener("submit", async (evento) => {
    evento.preventDefault();
    boton.setAttribute("disabled", "true");
    try {
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
