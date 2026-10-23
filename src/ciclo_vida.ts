/** Permite limpiar recursos de la vista actual (micrófono, timers) al navegar. */

type Limpieza = () => void;

let limpieza: Limpieza | null = null;

export function alSalir(fn: Limpieza): void {
  limpieza = fn;
}

export function limpiarVista(): void {
  const fn = limpieza;
  limpieza = null;
  fn?.();
}
