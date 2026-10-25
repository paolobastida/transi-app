import { fechaCorta, mesTexto } from "../formato";
import {
  agruparPorMes,
  lineaDeTiempo,
  resumenTratamiento,
  tituloTratamiento,
  tratamientoActivo,
  type Datos,
  type Evento,
  type Filtro,
} from "../modelo";
import { navegar } from "../rutas";
import { icono } from "../iconos";
import { h, vacio } from "../ui";

export function vistaLineaDeTiempo(datos: Datos, filtro: Filtro): HTMLElement {
  const eventos = lineaDeTiempo(datos, filtro);

  if (eventos.length === 0) {
    const hayDatos = datos.tratamientos.length + datos.cambios.length > 0;
    const mensaje = hayDatos
      ? filtro === "tratamientos"
        ? "No hay tratamientos con este filtro."
        : filtro === "cambios"
          ? "No hay cambios con este filtro."
          : "Todavía no hay registros para mostrar."
      : "Tu historia empieza con el primer registro. ¿Qué querés anotar?";

    const acciones: HTMLElement[] = [];
    if (hayDatos) {
      acciones.push(
        h(
          "button",
          { class: "btn secundario", type: "button", onClick: () => navegar("/") },
          "Ver todo",
        ),
      );
    }
    if (filtro !== "cambios") {
      acciones.push(
        h(
          "button",
          { class: "btn secundario", type: "button", onClick: () => navegar("/tratamiento") },
          icono("pildora"),
          "Anotar tratamiento",
        ),
      );
    }
    if (filtro !== "tratamientos") {
      acciones.push(
        h(
          "button",
          { class: "btn secundario", type: "button", onClick: () => navegar("/cambio") },
          icono("lapiz"),
          "Anotar cambio",
        ),
      );
    }

    return vacio("chispa", mensaje, acciones);
  }

  const contenedor = h("div", { class: "linea-tiempo" });
  for (const grupo of agruparPorMes(eventos)) {
    contenedor.append(h("h3", { class: "mes" }, mesTexto(`${grupo.mes}-01`)));
    for (const evento of grupo.eventos) {
      contenedor.append(filaEvento(evento));
    }
  }
  return contenedor;
}

/** Día del mes (1–31) de una fecha `AAAA-MM-DD`, como ancla visual del riel. */
function diaDelMes(iso: string): string {
  return String(Number(iso.slice(8, 10)));
}

function filaEvento(evento: Evento): HTMLElement {
  if (evento.tipo === "tratamiento") {
    const tratamiento = evento.tratamiento;
    const activo = tratamientoActivo(tratamiento);
    return fila({
      clase: "tratamiento",
      iconoEvento: "pildora",
      dia: diaDelMes(tratamiento.inicio),
      titulo: tituloTratamiento(tratamiento),
      detalle: `${resumenTratamiento(tratamiento) || "Tratamiento"} · desde ${fechaCorta(tratamiento.inicio)}`,
      etiqueta: activo ? { texto: "En curso", clase: "activo" } : { texto: "Finalizado", clase: "cerrado" },
      alAbrir: () => navegar(`/detalle/tratamiento/${tratamiento.id}`),
    });
  }

  const cambio = evento.cambio;
  return fila({
    clase: "cambio",
    iconoEvento: "lapiz",
    dia: diaDelMes(cambio.fecha),
    titulo: cambio.descripcion,
    detalle: fechaCorta(cambio.fecha),
    foto: cambio.foto,
    audio: Boolean(cambio.audio),
    alAbrir: () => navegar(`/detalle/cambio/${cambio.id}`),
  });
}

function fila(opciones: {
  clase: string;
  iconoEvento: "pildora" | "lapiz";
  dia: string;
  titulo: string;
  detalle: string;
  etiqueta?: { texto: string; clase: string };
  foto?: string | null;
  audio?: boolean;
  alAbrir: () => void;
}): HTMLElement {
  const abrir = opciones.alAbrir;
  return h(
    "div",
    { class: "evento-fila" },
    h(
      "div",
      { class: "riel", "aria-hidden": "true" },
      h("span", { class: `dia ${opciones.clase}` }, opciones.dia),
    ),
    h(
      "button",
      {
        class: "tarjeta evento",
        type: "button",
        onClick: abrir,
      },
      h(
        "div",
        { class: `icono-tarjeta ${opciones.clase === "tratamiento" ? "azul" : "rosa"}` },
        icono(opciones.iconoEvento),
      ),
      h(
        "div",
        { class: "fila-texto" },
        h("strong", {}, opciones.titulo),
        h("span", {}, opciones.detalle),
      ),
      opciones.etiqueta
        ? h("span", { class: `etiqueta ${opciones.etiqueta.clase}` }, opciones.etiqueta.texto)
        : null,
      opciones.audio
        ? h(
            "span",
            { class: "mini-audio", title: "Tiene nota de voz", "aria-label": "Tiene nota de voz" },
            icono("microfono"),
          )
        : null,
      opciones.foto
        ? h("img", { class: "miniatura", src: opciones.foto, alt: "Foto del cambio", loading: "lazy" })
        : null,
    ),
  );
}
