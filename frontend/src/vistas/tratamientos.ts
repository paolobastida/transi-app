import { api } from "../api";
import { fechaTexto } from "../formato";
import { irATratamiento } from "../navegacion";
import type { Tratamiento, Usuario } from "../tipos";
import { aviso, cargando, h, vacio } from "../ui";
import { botonFiltro, etiquetaEstado } from "./comunes";

const FILTROS = [
  { clave: "activo", texto: "Activos" },
  { clave: "finalizado", texto: "Finalizados" },
  { clave: "todos", texto: "Todos" },
];

export function vistaTratamientos(usuario: Usuario): HTMLElement {
  let filtro = "activo";
  const lista = h("div", { class: "lista" });
  const chips = h("div", { class: "chips" });

  const cargar = async () => {
    lista.replaceChildren(cargando());
    try {
      const tratamientos = await api.listarTratamientos(
        usuario.id,
        filtro === "todos" ? undefined : filtro,
      );
      if (tratamientos.length === 0) {
        lista.replaceChildren(
          vacio("💊", "No hay tratamientos todavía."),
        );
        return;
      }
      lista.replaceChildren(...tratamientos.map((t) => tarjeta(t, usuario)));
    } catch (error) {
      lista.replaceChildren(vacio("⚠️", "No pudimos cargar los tratamientos."));
      aviso(String(error), true);
    }
  };

  const pintarFiltros = () => {
    chips.replaceChildren(
      ...FILTROS.map((opcion) =>
        botonFiltro(opcion.texto, filtro === opcion.clave, () => {
          filtro = opcion.clave;
          pintarFiltros();
          void cargar();
        }),
      ),
    );
  };

  pintarFiltros();
  void cargar();

  return h(
    "div",
    { class: "vista" },
    h(
      "div",
      { class: "filtros" },
      chips,
      h(
        "button",
        {
          class: "btn primario chico",
          onClick: () => irATratamiento(usuario),
        },
        "+ Agregar tratamiento",
      ),
    ),
    lista,
  );
}

function tarjeta(tratamiento: Tratamiento, usuario: Usuario): HTMLElement {
  const detalles = [
    tratamiento.dosis,
    tratamiento.via ?? "",
    tratamiento.frecuencia,
  ]
    .filter(Boolean)
    .join(" · ");

  return h(
    "article",
    {
      class: "tarjeta tratamiento",
      role: "button",
      tabindex: "0",
      onClick: () => irATratamiento(usuario, tratamiento),
      onKeydown: (evento: KeyboardEvent) => {
        if (evento.key === "Enter" || evento.key === " ") {
          evento.preventDefault();
          irATratamiento(usuario, tratamiento);
        }
      },
    },
    h("div", { class: "icono-tarjeta" }, "💊"),
    h(
      "div",
      { class: "fila-texto" },
      h("strong", {}, tratamiento.nombre),
      h("span", {}, detalles),
      h("span", {}, `Desde ${fechaTexto(tratamiento.fechaInicio)}`),
      tratamiento.profesionalNombre
        ? h(
            "span",
            {},
            tratamiento.profesionalEspecialidad
              ? `${tratamiento.profesionalNombre} · ${tratamiento.profesionalEspecialidad}`
              : tratamiento.profesionalNombre,
          )
        : null,
    ),
    etiquetaEstado(tratamiento.fechaFin != null),
  );
}
