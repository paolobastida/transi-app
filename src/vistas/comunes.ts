import { icono } from "../iconos";
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
      icono("atras"),
    ),
    h("h1", {}, titulo),
    accion ?? h("span", { class: "barra-hueco" }),
  );
}

let secuenciaCampo = 0;

export function campo(
  etiqueta: string,
  control: HTMLElement,
  ayuda?: string,
  opcional = false,
): HTMLElement {
  const idAyuda = `campo-ayuda-${++secuenciaCampo}`;
  if (ayuda) {
    const previo = control.getAttribute("aria-describedby");
    control.setAttribute("aria-describedby", previo ? `${previo} ${idAyuda}` : idAyuda);
  }

  return h(
    "label",
    { class: "campo" },
    h(
      "span",
      { class: "campo-etiqueta" },
      etiqueta,
      opcional ? h("em", { class: "campo-opcional" }, "Opcional") : null,
    ),
    control,
    ayuda ? h("p", { class: "ayuda", id: idAyuda }, ayuda) : null,
  );
}

export function barraGuardar(texto = "Guardar"): HTMLElement {
  return h(
    "div",
    { class: "barra-guardar" },
    h("button", { class: "btn primario", type: "submit" }, texto),
  );
}
