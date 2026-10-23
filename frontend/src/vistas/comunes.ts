import { h } from "../ui";

/** Chip de filtro reutilizado por la línea de tiempo y tratamientos. */
export function botonFiltro(
  texto: string,
  activo: boolean,
  alTocar: () => void,
): HTMLElement {
  return h(
    "button",
    {
      type: "button",
      class: `chip-filtro ${activo ? "activa" : ""}`,
      onClick: alTocar,
    },
    texto,
  );
}

/** Etiqueta de estado (activo / finalizado). */
export function etiquetaEstado(finalizado: boolean): HTMLElement {
  return h(
    "span",
    { class: `etiqueta ${finalizado ? "cerrado" : "activo"}` },
    finalizado ? "Finalizado" : "Activo",
  );
}
