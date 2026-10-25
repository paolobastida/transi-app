/** Helpers mínimos de UI: crear nodos, montar vistas y avisar. */

import { icono, type NombreIcono } from "./iconos";

export type Hijo = Node | string | number | null | undefined | false;

const PROPIEDADES = new Set(["value", "checked", "disabled", "selected", "indeterminate"]);

export function h<K extends keyof HTMLElementTagNameMap>(
  tag: K,
  atributos: Record<string, unknown> = {},
  ...hijos: Hijo[]
): HTMLElementTagNameMap[K] {
  const nodo = document.createElement(tag);
  for (const [clave, valor] of Object.entries(atributos)) {
    if (valor === null || valor === undefined || valor === false) continue;
    if (clave === "class") {
      nodo.className = String(valor);
    } else if (PROPIEDADES.has(clave)) {
      (nodo as unknown as Record<string, unknown>)[clave] = valor;
    } else if (clave.startsWith("on") && typeof valor === "function") {
      nodo.addEventListener(clave.slice(2).toLowerCase(), valor as EventListener);
    } else {
      nodo.setAttribute(clave, String(valor));
    }
  }
  for (const hijo of hijos) {
    if (hijo === null || hijo === undefined || hijo === false) continue;
    nodo.append(hijo instanceof Node ? hijo : document.createTextNode(String(hijo)));
  }
  return nodo;
}

const raiz = () => document.querySelector<HTMLDivElement>("#app");

export function montar(vista: HTMLElement): void {
  raiz()?.replaceChildren(vista);

  // Al cambiar de pantalla, llevamos el foco al contenido: lectores de pantalla
  // y teclado no tienen que recorrer toda la cabecera otra vez.
  const principal = vista.querySelector<HTMLElement>("main");
  if (principal) {
    principal.id = "contenido";
    principal.tabIndex = -1;
    principal.focus({ preventScroll: true });
  }

  window.scrollTo({ top: 0 });
}

export function aviso(mensaje: string, esError = false, duracion?: number): void {
  const contenedor = document.querySelector<HTMLDivElement>("#avisos");
  if (!contenedor) return;

  // Un mensaje repetido se refresca en vez de apilarse dos veces.
  for (const repetido of contenedor.querySelectorAll<HTMLElement>(".aviso")) {
    if (repetido.querySelector(".aviso-texto")?.textContent === mensaje) repetido.remove();
  }

  const texto = h("span", { class: "aviso-texto" }, mensaje);
  const nodo = h(
    "div",
    {
      class: `aviso ${esError ? "error" : ""}`,
      role: esError ? "alert" : "status",
      "aria-atomic": "true",
    },
    texto,
  );
  const cerrar = h(
    "button",
    {
      class: "aviso-cerrar",
      type: "button",
      "aria-label": "Cerrar aviso",
      onClick: () => nodo.remove(),
    },
    "×",
  );
  nodo.append(cerrar);
  contenedor.append(nodo);

  // Los errores necesitan más tiempo para poder leerse con calma.
  setTimeout(() => nodo.remove(), duracion ?? (esError ? 8000 : 4600));
}

export function confirmar(mensaje: string): boolean {
  return window.confirm(mensaje);
}

/**
 * Baja un archivo al dispositivo. El ancla va al DOM y se retira: Safari (y
 * sobre todo la versión instalada como app) ignora las que nunca se insertaron.
 */
export function descargar(nombre: string, contenido: string, tipo: string): void {
  const url = URL.createObjectURL(new Blob([contenido], { type: tipo }));
  const enlace = h("a", { href: url, download: nombre });
  document.body.append(enlace);
  enlace.click();
  enlace.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

export function vacio(
  nombre: NombreIcono,
  mensaje: string,
  acciones: HTMLElement[] = [],
): HTMLElement {
  return h(
    "div",
    { class: "vacio" },
    h("div", { class: "vacio-icono" }, icono(nombre)),
    h("p", {}, mensaje),
    acciones.length
      ? h("div", { class: "fila-botones vacio-acciones" }, ...acciones)
      : null,
  );
}
