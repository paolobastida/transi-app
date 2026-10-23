/** Helpers mínimos de UI: crear nodos, montar vistas y avisar. */

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
  window.scrollTo({ top: 0 });
}

export function aviso(mensaje: string, esError = false): void {
  const contenedor = document.querySelector<HTMLDivElement>("#avisos");
  if (!contenedor) return;
  const nodo = h("div", { class: `aviso ${esError ? "error" : ""}`, role: "status" }, mensaje);
  contenedor.append(nodo);
  setTimeout(() => nodo.remove(), 4600);
}

export function confirmar(mensaje: string): boolean {
  return window.confirm(mensaje);
}

export function vacio(icono: string, mensaje: string): HTMLElement {
  return h(
    "div",
    { class: "vacio" },
    h("div", { class: "vacio-icono", "aria-hidden": "true" }, icono),
    h("p", {}, mensaje),
  );
}
