/** Helpers mínimos de UI: crear nodos, montar vistas y avisar. */

export type Hijo = Node | string | number | null | undefined | false;

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
    } else if (clave === "value") {
      (nodo as unknown as HTMLInputElement).value = String(valor);
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

export function cargando(): HTMLElement {
  return h("div", { class: "cargando" }, h("div", { class: "spinner" }));
}

export function aviso(mensaje: string, esError = false): void {
  const contenedor = document.querySelector<HTMLDivElement>("#avisos");
  if (!contenedor) return;
  const nodo = h("div", { class: `aviso ${esError ? "error" : ""}` }, mensaje);
  contenedor.append(nodo);
  setTimeout(() => nodo.remove(), 4200);
}

export function confirmar(mensaje: string): boolean {
  return window.confirm(mensaje);
}

export function vacio(icono: string, mensaje: string): HTMLElement {
  return h(
    "div",
    { class: "vacio" },
    h("div", { class: "vacio-icono" }, icono),
    h("p", {}, mensaje),
  );
}
