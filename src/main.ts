import { claveActiva, configurarPerfil, invalidarMemoria, respaldoRoto } from "./almacen";
import { accesoOmitido, leerPerfil } from "./auth";
import { limpiarVista } from "./ciclo_vida";
import { clavePerfil } from "./perfil";
import { registrarServiceWorker } from "./pwa";
import { iniciarRecordatorios, sincronizarSiCambio } from "./recordatorios";
import { analizarRuta, navegar, rutaActual } from "./rutas";
import { aviso, montar } from "./ui";
import { vistaAplicaciones } from "./vistas/aplicaciones";
import { vistaAjustes } from "./vistas/ajustes";
import { vistaAyuda } from "./vistas/ayuda";
import { vistaDetalleCambio } from "./vistas/detalle_cambio";
import { vistaDetalleTratamiento } from "./vistas/detalle_tratamiento";
import { vistaEntrada } from "./vistas/entrada";
import { vistaFormularioCambio } from "./vistas/formulario_cambio";
import { vistaFormularioTratamiento } from "./vistas/formulario_tratamiento";
import { vistaInicio } from "./vistas/inicio";
import { vistaRegistrar } from "./vistas/registrar";

function render(): void {
  limpiarVista();
  const pantalla = analizarRuta(rutaActual());

  switch (pantalla.nombre) {
    case "inicio":
      montar(vistaInicio());
      return;
    case "entrada":
      montar(vistaEntrada());
      return;
    case "registrar":
      montar(vistaRegistrar());
      return;
    case "tratamiento":
      montar(vistaFormularioTratamiento(pantalla.id));
      return;
    case "cambio":
      montar(vistaFormularioCambio(pantalla.id));
      return;
    case "detalle":
      montar(
        pantalla.tipo === "tratamiento"
          ? vistaDetalleTratamiento(pantalla.id)
          : vistaDetalleCambio(pantalla.id),
      );
      return;
    case "aplicaciones":
      montar(vistaAplicaciones());
      return;
    case "ajustes":
      montar(vistaAjustes());
      return;
    case "ayuda":
      montar(vistaAyuda());
      return;
    case "desconocida":
      navegar("/");
  }
}

// Restaura el perfil (anónimo o de Google, Apple o Facebook) antes del primer render.
const perfilInicial = leerPerfil();
configurarPerfil(perfilInicial ? clavePerfil(perfilInicial) : null);

// Primera visita: ofrecer cuenta (opcional) antes de la app.
if (!perfilInicial && !accesoOmitido()) {
  window.location.hash = "/entrar";
}

window.addEventListener("hashchange", render);
render();

// El enlace de salto no puede usar un hash: el router lo interpretaría como ruta.
document.querySelector<HTMLButtonElement>(".saltar-contenido")?.addEventListener("click", () => {
  document.querySelector<HTMLElement>("main")?.focus();
});

// Si el respaldo no se pudo leer, lo avisamos apenas arrancamos: sin este aviso,
// la pantalla de bienvenida haría creer que los datos desaparecieron solos.
if (respaldoRoto() !== null) {
  aviso("No pudimos leer tu respaldo. Guardamos una copia aparte: bajala desde Ajustes.", true);
}

// Otra pestaña (u otra ventana de la app instalada) guardó: refrescamos.
// En los formularios no repintamos, para no tirar lo que se está escribiendo;
// ahí la escritura vuelve a leer el almacen al guardar (ver `actualizar`).
window.addEventListener("storage", (evento: StorageEvent) => {
  if (evento.key !== null && evento.key !== claveActiva()) return;
  invalidarMemoria();
  sincronizarSiCambio();
  const pantalla = analizarRuta(rutaActual()).nombre;
  if (pantalla === "tratamiento" || pantalla === "cambio") return;
  render();
});

// Revisa los horarios de los medicamentos cada 20 s mientras la app esté abierta.
iniciarRecordatorios();

// Tranquiliza: la app es local-first, así que seguir sin conexión es normal.
window.addEventListener("offline", () => {
  aviso("Sin conexión. Transi sigue funcionando y tus datos están en este dispositivo.");
});
window.addEventListener("online", () => {
  aviso("Volviste a estar en línea.");
});

// En desarrollo no registramos el service worker para no interferir con Vite/HMR.
if (import.meta.env.PROD) registrarServiceWorker();
