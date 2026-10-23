import { cargar, guardar } from "../almacen";
import { fechaLarga } from "../formato";
import { tratamientoActivo } from "../modelo";
import { navegar } from "../rutas";
import { aviso, confirmar, h } from "../ui";
import { cabeceraVista } from "./comunes";

export function vistaDetalleTratamiento(id: string): HTMLElement {
  const datos = cargar();
  const tratamiento = datos.tratamientos.find((item) => item.id === id);

  if (!tratamiento) {
    navegar("/");
    return h("div");
  }

  const activo = tratamientoActivo(tratamiento);

  const eliminar = (): void => {
    if (!confirmar(`¿Borrar "${tratamiento.nombre}"? No se puede deshacer.`)) return;
    const nuevos = {
      ...datos,
      tratamientos: datos.tratamientos.filter((item) => item.id !== tratamiento.id),
    };
    if (!guardar(nuevos)) {
      aviso("No pudimos borrar el tratamiento.", true);
      return;
    }
    aviso("Tratamiento borrado.");
    navegar("/");
  };

  return h(
    "div",
    { class: "pantalla-detalle" },
    cabeceraVista("Tratamiento", () => navegar("/")),
    h(
      "main",
      { class: "contenido" },
      h(
        "section",
        { class: "tarjeta ficha" },
        h(
          "div",
          { class: "ficha-cabecera" },
          h("div", {}, h("h2", {}, tratamiento.nombre), h("p", { class: "sub" }, "Registrado en tu historia")),
          h("span", { class: `etiqueta ${activo ? "activo" : "cerrado"}` }, activo ? "En curso" : "Finalizado"),
        ),
        h(
          "dl",
          { class: "datos" },
          dato("Dosis", tratamiento.dosis || "—"),
          dato("Frecuencia", tratamiento.frecuencia || "—"),
          dato("Inicio", fechaLarga(tratamiento.inicio)),
          dato("Fin", tratamiento.fin ? fechaLarga(tratamiento.fin) : "Sin fecha de fin"),
          dato("Profesional", tratamiento.profesional ?? "—"),
        ),
      ),
      h(
        "div",
        { class: "fila-botones" },
        h(
          "button",
          {
            class: "btn primario",
            type: "button",
            onClick: () => navegar(`/tratamiento/${tratamiento.id}`),
          },
          "Editar",
        ),
        h("button", { class: "btn peligro", type: "button", onClick: eliminar }, "Borrar"),
      ),
    ),
  );
}

function dato(etiqueta: string, valor: string): HTMLElement {
  return h(
    "div",
    { class: "dato" },
    h("dt", {}, etiqueta),
    h("dd", {}, valor),
  );
}
