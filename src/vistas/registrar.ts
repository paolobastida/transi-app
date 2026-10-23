import { navegar } from "../rutas";
import { icono, type NombreIcono } from "../iconos";
import { h } from "../ui";
import { cabeceraFormulario } from "./comunes";

export function vistaRegistrar(): HTMLElement {
  const opcion = (
    nombre: NombreIcono,
    tono: "azul" | "rosa",
    titulo: string,
    detalle: string,
    alElegir: () => void,
  ): HTMLElement =>
    h(
      "button",
      { class: "tarjeta opcion", type: "button", onClick: alElegir },
      h("span", { class: `icono-tarjeta grande ${tono}` }, icono(nombre)),
      h("span", { class: "opcion-texto" }, h("strong", {}, titulo), h("span", {}, detalle)),
      h("span", { class: "opcion-flecha", "aria-hidden": "true" }, icono("flecha")),
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
        "pildora",
        "azul",
        "Un tratamiento",
        "Uno o varios medicamentos, dosis, fechas y profesional.",
        () => navegar("/tratamiento"),
      ),
      opcion(
        "lapiz",
        "rosa",
        "Un cambio",
        "Una fecha, un texto y, si querés, una foto o una nota de voz.",
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
