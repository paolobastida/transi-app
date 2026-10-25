/** Instalación como app (PWA) y registro del service worker. */

type EventoInstalacion = Event & {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed" }>;
};

export type EstadoInstalacion = "instalada" | "disponible" | "ios" | "navegador";

let eventoInstalacion: EventoInstalacion | null = null;
const oyentes = new Set<(estado: EstadoInstalacion) => void>();

export function estadoInstalacion(): EstadoInstalacion {
  if (modoInstalado()) return "instalada";
  if (eventoInstalacion) return "disponible";
  if (esIOS()) return "ios";
  return "navegador";
}

/** Suscribe a cambios de instalación. Devuelve la función para desuscribirse. */
export function alCambiarInstalacion(
  oyente: (estado: EstadoInstalacion) => void,
): () => void {
  oyentes.add(oyente);
  oyente(estadoInstalacion());
  return () => {
    oyentes.delete(oyente);
  };
}

/** Abre el diálogo nativo de instalación. Devuelve si la persona aceptó. */
export async function pedirInstalacion(): Promise<boolean> {
  if (!eventoInstalacion) return false;
  const evento = eventoInstalacion;
  eventoInstalacion = null;
  await evento.prompt();
  const eleccion = await evento.userChoice;
  notificar();
  return eleccion.outcome === "accepted";
}

export function registrarServiceWorker(): void {
  if (!("serviceWorker" in navigator)) return;
  window.addEventListener("load", () => {
    void navigator.serviceWorker.register("./sw.js").catch(() => {
      // Sin service worker la app sigue funcionando; solo se pierde el uso offline.
    });
  });
}

function notificar(): void {
  const actual = estadoInstalacion();
  for (const oyente of oyentes) oyente(actual);
}

function modoInstalado(): boolean {
  return (
    window.matchMedia("(display-mode: standalone)").matches ||
    window.matchMedia("(display-mode: window-controls-overlay)").matches ||
    (navigator as Navigator & { standalone?: boolean }).standalone === true
  );
}

function esIOS(): boolean {
  const ua = navigator.userAgent;
  const iPadOS = /Macintosh/.test(ua) && navigator.maxTouchPoints > 1;
  return /iPad|iPhone|iPod/.test(ua) || iPadOS;
}

window.addEventListener("beforeinstallprompt", (evento) => {
  evento.preventDefault();
  eventoInstalacion = evento as EventoInstalacion;
  notificar();
});

window.addEventListener("appinstalled", () => {
  eventoInstalacion = null;
  notificar();
});
