import { cargar, guardar } from "../almacen";
import { fechaLarga } from "../formato";
import { navegar } from "../rutas";
import { aviso, confirmar, h } from "../ui";
import { cabeceraVista } from "./comunes";

export function vistaDetalleCambio(id: string): HTMLElement {
  const datos = cargar();
  const cambio = datos.cambios.find((item) => item.id === id);

  if (!cambio) {
    navegar("/");
    return h("div");
  }

  const eliminar = (): void => {
    if (!confirmar("¿Borrar este cambio? No se puede deshacer.")) return;
    const nuevos = {
      ...datos,
      cambios: datos.cambios.filter((item) => item.id !== cambio.id),
    };
    if (!guardar(nuevos)) {
      aviso("No pudimos borrar el cambio.", true);
      return;
    }
    aviso("Cambio borrado.");
    navegar("/");
  };

  return h(
    "div",
    { class: "pantalla-detalle" },
    cabeceraVista("Cambio", () => navegar("/")),
    h(
      "main",
      { class: "contenido" },
      h(
        "section",
        { class: "tarjeta ficha" },
        h("span", { class: "etiqueta cambio" }, "Cambio"),
        h("h2", { class: "fecha-detalle" }, fechaLarga(cambio.fecha)),
        h("p", { class: "descripcion" }, cambio.descripcion),
        cambio.foto
          ? h("img", { class: "foto-detalle", src: cambio.foto, alt: "Foto de este cambio" })
          : null,
      ),
      h(
        "div",
        { class: "fila-botones" },
        h(
          "button",
          {
            class: "btn primario",
            type: "button",
            onClick: () => navegar(`/cambio/${cambio.id}`),
          },
          "Editar",
        ),
        h("button", { class: "btn peligro", type: "button", onClick: eliminar }, "Borrar"),
      ),
    ),
  );
}
