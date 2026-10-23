import { fechaCorta, mesTexto } from "../formato";
import {
  agruparPorMes,
  lineaDeTiempo,
  resumenTratamiento,
  tratamientoActivo,
  type Datos,
  type Evento,
  type Filtro,
} from "../modelo";
import { navegar } from "../rutas";
import { h, vacio } from "../ui";

export function vistaLineaDeTiempo(datos: Datos, filtro: Filtro): HTMLElement {
  const eventos = lineaDeTiempo(datos, filtro);

  if (eventos.length === 0) {
    const mensaje =
      filtro === "tratamientos"
        ? "Todavía no registraste tratamientos."
        : filtro === "cambios"
          ? "Todavía no registraste cambios."
          : "Tu historia empieza con el primer registro.";
    return vacio("✦", mensaje);
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

function filaEvento(evento: Evento): HTMLElement {
  if (evento.tipo === "tratamiento") {
    const tratamiento = evento.tratamiento;
    const activo = tratamientoActivo(tratamiento);
    return fila({
      clase: "tratamiento",
      icono: "💊",
      titulo: tratamiento.nombre,
      detalle: `${resumenTratamiento(tratamiento) || "Tratamiento"} · desde ${fechaCorta(tratamiento.inicio)}`,
      etiqueta: activo ? { texto: "En curso", clase: "activo" } : { texto: "Finalizado", clase: "cerrado" },
      alAbrir: () => navegar(`/detalle/tratamiento/${tratamiento.id}`),
    });
  }

  const cambio = evento.cambio;
  return fila({
    clase: "cambio",
    icono: "✎",
    titulo: cambio.descripcion,
    detalle: fechaCorta(cambio.fecha),
    foto: cambio.foto,
    alAbrir: () => navegar(`/detalle/cambio/${cambio.id}`),
  });
}

function fila(opciones: {
  clase: string;
  icono: string;
  titulo: string;
  detalle: string;
  etiqueta?: { texto: string; clase: string };
  foto?: string | null;
  alAbrir: () => void;
}): HTMLElement {
  const abrir = opciones.alAbrir;
  return h(
    "div",
    { class: "evento-fila" },
    h(
      "div",
      { class: "riel", "aria-hidden": "true" },
      h("span", { class: `punto ${opciones.clase}` }),
      h("span", { class: "linea" }),
    ),
    h(
      "article",
      {
        class: "tarjeta evento",
        role: "button",
        tabindex: "0",
        onClick: abrir,
        onKeyDown: (evento: Event) => {
          const tecla = (evento as KeyboardEvent).key;
          if (tecla === "Enter" || tecla === " ") {
            evento.preventDefault();
            abrir();
          }
        },
      },
      h("div", { class: "icono-tarjeta", "aria-hidden": "true" }, opciones.icono),
      h(
        "div",
        { class: "fila-texto" },
        h("strong", {}, opciones.titulo),
        h("span", {}, opciones.detalle),
      ),
      opciones.etiqueta
        ? h("span", { class: `etiqueta ${opciones.etiqueta.clase}` }, opciones.etiqueta.texto)
        : null,
      opciones.foto
        ? h("img", { class: "miniatura", src: opciones.foto, alt: "Foto del cambio", loading: "lazy" })
        : null,
    ),
  );
}
