import { h } from "../ui";

/** Barra superior de un formulario: cancelar a la izquierda, título al centro. */
export function cabeceraFormulario(titulo: string, alCancelar: () => void): HTMLElement {
  return h(
    "header",
    { class: "barra-superior" },
    h("button", { class: "btn enlace", type: "button", onClick: alCancelar }, "Cancelar"),
    h("h1", {}, titulo),
    h("span", { class: "barra-hueco" }),
  );
}

/** Barra superior de una pantalla de lectura: volver + título. */
export function cabeceraVista(titulo: string, alVolver: () => void, accion?: HTMLElement): HTMLElement {
  return h(
    "header",
    { class: "barra-superior" },
    h(
      "button",
      { class: "btn icono", type: "button", title: "Volver", "aria-label": "Volver", onClick: alVolver },
      "←",
    ),
    h("h1", {}, titulo),
    accion ?? h("span", { class: "barra-hueco" }),
  );
}

export function campo(etiqueta: string, control: HTMLElement, ayuda?: string): HTMLElement {
  return h(
    "label",
    { class: "campo" },
    h("span", {}, etiqueta),
    control,
    ayuda ? h("p", { class: "ayuda" }, ayuda) : null,
  );
}

export function barraGuardar(texto = "Guardar"): HTMLElement {
  return h(
    "div",
    { class: "barra-guardar" },
    h("button", { class: "btn primario", type: "submit" }, texto),
  );
}
