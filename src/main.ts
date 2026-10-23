import { limpiarVista } from "./ciclo_vida";
import { analizarRuta, navegar, rutaActual } from "./rutas";
import { montar } from "./ui";
import { vistaAjustes } from "./vistas/ajustes";
import { vistaDetalleCambio } from "./vistas/detalle_cambio";
import { vistaDetalleTratamiento } from "./vistas/detalle_tratamiento";
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
    case "ajustes":
      montar(vistaAjustes());
      return;
    case "desconocida":
      navegar("/");
  }
}

window.addEventListener("hashchange", render);
render();
