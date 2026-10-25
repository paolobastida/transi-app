/** Rutas por hash: funcionan en cualquier hosting estático y respetan el botón Atrás. */

export type Pantalla =
  | { nombre: "inicio" }
  | { nombre: "registrar" }
  | { nombre: "tratamiento"; id?: string }
  | { nombre: "cambio"; id?: string }
  | { nombre: "detalle"; tipo: "tratamiento" | "cambio"; id: string }
  | { nombre: "aplicaciones" }
  | { nombre: "ajustes" }
  | { nombre: "ayuda" }
  | { nombre: "desconocida" };

/** Traduce `/detalle/cambio/123` a una pantalla con sus parámetros. */
export function analizarRuta(ruta: string): Pantalla {
  const [seccion, primero, segundo] = ruta.split("/").filter(Boolean);

  switch (seccion) {
    case undefined:
      return { nombre: "inicio" };
    case "registrar":
      return { nombre: "registrar" };
    case "tratamiento":
      return { nombre: "tratamiento", id: primero };
    case "cambio":
      return { nombre: "cambio", id: primero };
    case "detalle":
      if ((primero === "tratamiento" || primero === "cambio") && segundo) {
        return { nombre: "detalle", tipo: primero, id: segundo };
      }
      return { nombre: "desconocida" };
    case "aplicaciones":
      return { nombre: "aplicaciones" };
    case "ajustes":
      return { nombre: "ajustes" };
    case "ayuda":
      return { nombre: "ayuda" };
    default:
      return { nombre: "desconocida" };
  }
}

export function navegar(ruta: string): void {
  const destino = ruta.startsWith("/") ? ruta : `/${ruta}`;
  if (rutaActual() === destino) {
    window.dispatchEvent(new HashChangeEvent("hashchange"));
    return;
  }
  window.location.hash = destino;
}

export function rutaActual(): string {
  const hash = window.location.hash.replace(/^#/, "");
  return hash || "/";
}

export function segmentos(): string[] {
  return rutaActual().split("/").filter(Boolean);
}
