import { api } from "../api";
import { fechaHoraTexto } from "../formato";
import { irAInicio, irALogin } from "../navegacion";
import type { Usuario } from "../tipos";
import { aviso, confirmar, h } from "../ui";

export function vistaCuenta(usuario: Usuario): HTMLElement {
  const ultimo = h("span", { class: "valor" }, "…");
  const pendientes = h("span", { class: "valor" }, "…");

  let botonRespaldar: HTMLButtonElement;
  let botonRestaurar: HTMLButtonElement;

  const cargar = async () => {
    try {
      const [fecha, cantidad] = await Promise.all([
        api.ultimoRespaldo(),
        api.pendientes(usuario.id),
      ]);
      ultimo.textContent = fecha ? fechaHoraTexto(fecha) : "Todavía no respaldaste";
      pendientes.textContent = String(cantidad);
    } catch (error) {
      aviso(String(error), true);
    }
  };

  const ejecutar = async (
    accion: () => Promise<void>,
    exito: string,
    error: string,
  ) => {
    botonRespaldar?.setAttribute("disabled", "true");
    botonRestaurar?.setAttribute("disabled", "true");
    try {
      await accion();
      aviso(exito);
    } catch (causa) {
      aviso(`${error}: ${String(causa)}`, true);
    } finally {
      botonRespaldar?.removeAttribute("disabled");
      botonRestaurar?.removeAttribute("disabled");
      await cargar();
    }
  };

  const restaurar = async () => {
    const seguro = confirmar(
      "Se van a reemplazar los datos de este dispositivo con el último respaldo guardado. ¿Continuar?",
    );
    if (!seguro) return;
    await ejecutar(
      () => api.restaurar(usuario.id),
      "Datos restaurados",
      "No se pudo restaurar",
    );
  };

  const salir = async () => {
    const seguro = confirmar(
      "¿Cerrar sesión? Los datos locales de salud se borran del dispositivo (quedan en tu respaldo).",
    );
    if (!seguro) return;
    try {
      await api.salir();
      irALogin();
    } catch (error) {
      aviso(String(error), true);
    }
  };

  botonRespaldar = h(
    "button",
    {
      class: "btn primario",
      onClick: () =>
        void ejecutar(
          () => api.respaldar(usuario.id),
          "Respaldo listo",
          "No se pudo respaldar",
        ),
    },
    "☁ Respaldar ahora",
  );

  botonRestaurar = h(
    "button",
    { class: "btn secundario", onClick: () => void restaurar() },
    "⬇ Restaurar",
  );

  void cargar();

  return h(
    "div",
    { class: "pantalla-formulario" },
    h(
      "header",
      { class: "cabecera" },
      h(
        "button",
        { class: "btn icono", title: "Volver", onClick: () => irAInicio(usuario, 0) },
        "‹",
      ),
      h("span", { class: "titulo" }, "Cuenta y respaldo"),
      h("span"),
    ),
    h(
      "div",
      { class: "contenido" },
      h(
        "section",
        { class: "tarjeta datos" },
        h("div", { class: "dato" }, h("span", {}, "Cuenta"), h("strong", {}, usuario.email)),
        h("div", { class: "dato" }, h("span", {}, "Último respaldo"), ultimo),
        h("div", { class: "dato" }, h("span", {}, "Pendientes de respaldar"), pendientes),
      ),
      h("div", { class: "botones-cuenta" }, botonRespaldar, botonRestaurar),
      h(
        "p",
        { class: "ayuda" },
        "El respaldo guarda una copia completa de tus datos en el servidor. Usalo para pasar tu información a otro teléfono.",
      ),
      h(
        "button",
        { class: "btn peligro", onClick: () => void salir() },
        "Cerrar sesión",
      ),
    ),
  );
}
