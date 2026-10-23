import { navegar } from "../rutas";
import { h } from "../ui";
import { cabeceraFormulario } from "./comunes";

export function vistaRegistrar(): HTMLElement {
  const opcion = (icono: string, titulo: string, detalle: string, alElegir: () => void): HTMLElement =>
    h(
      "button",
      { class: "tarjeta opcion", type: "button", onClick: alElegir },
      h("span", { class: "icono-tarjeta grande", "aria-hidden": "true" }, icono),
      h("span", { class: "opcion-texto" }, h("strong", {}, titulo), h("span", {}, detalle)),
      h("span", { class: "opcion-flecha", "aria-hidden": "true" }, "→"),
    );

  return h(
    "div",
    { class: "pantalla-formulario" },
    cabeceraFormulario("¿Qué querés registrar?", () => navegar("/")),
    h(
      "main",
      { class: "contenido" },
      h(
        "p",
        { class: "intro" },
        "Elegí una opción. Podés editarla o borrarla cuando quieras.",
      ),
      opcion(
        "💊",
        "Un tratamiento",
        "Medicamento, dosis, fechas y profesional.",
        () => navegar("/tratamiento"),
      ),
      opcion(
        "✎",
        "Un cambio",
        "Una fecha, una nota y, si querés, una foto.",
        () => navegar("/cambio"),
      ),
      h(
        "p",
        { class: "nota-local" },
        "Todo se guarda en este dispositivo. No se envía a ningún servidor.",
      ),
    ),
  );
}
