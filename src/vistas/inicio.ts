import { cargar, guardar } from "../almacen";
import { duracionTexto } from "../formato";
import {
  datosDemo,
  resumenTratamiento,
  tratamientosEnCurso,
  type Datos,
  type Filtro,
  type Tratamiento,
} from "../modelo";
import { navegar } from "../rutas";
import { aviso, h } from "../ui";
import { vistaLineaDeTiempo } from "./linea_de_tiempo";

export function vistaInicio(filtroInicial: Filtro = "todo"): HTMLElement {
  const datos = cargar();
  let filtro = filtroInicial;

  const contenido = h("div", { class: "contenido-inicio" });
  const acciones = h("div", { class: "fab-contenedor" });

  const botonFiltro = (texto: string, valor: Filtro): HTMLElement =>
    h(
      "button",
      {
        class: `chip-filtro ${filtro === valor ? "activa" : ""}`,
        type: "button",
        onClick: () => {
          filtro = valor;
          pintar();
        },
      },
      texto,
    );

  const pintar = (): void => {
    if (datos.tratamientos.length === 0 && datos.cambios.length === 0) {
      contenido.replaceChildren(bienvenida());
      acciones.replaceChildren();
      return;
    }

    contenido.replaceChildren(
      ...(tratamientosEnCurso(datos).length ? [enCurso(datos)] : []),
      h(
        "div",
        { class: "filtros" },
        h("h2", { class: "seccion-titulo" }, "Tu historia"),
        h(
          "div",
          { class: "chips" },
          botonFiltro("Todo", "todo"),
          botonFiltro("Tratamientos", "tratamientos"),
          botonFiltro("Cambios", "cambios"),
        ),
      ),
      vistaLineaDeTiempo(datos, filtro),
      h(
        "p",
        { class: "pie" },
        "Tus datos no salen de este dispositivo. Podés exportarlos desde Ajustes.",
      ),
    );

    acciones.replaceChildren(
      h(
        "button",
        { class: "fab", type: "button", onClick: () => navegar("/registrar") },
        "＋ Registrar",
      ),
    );
  };

  const usarDemo = (): void => {
    if (guardar(datosDemo())) {
      aviso("Cargamos datos de ejemplo. Podés borrarlos desde Ajustes.");
      navegar("/");
    } else {
      aviso("No pudimos guardar los datos de ejemplo.", true);
    }
  };

  const bienvenida = (): HTMLElement =>
    h(
      "section",
      { class: "bienvenida tarjeta" },
      h("span", { class: "logo grande", "aria-hidden": "true" }),
      h("h1", {}, "Tu transición, a tu ritmo"),
      h(
        "p",
        {},
        "Registrá tus tratamientos y los cambios que notes, en un solo lugar. " +
          "Sin cuentas ni servidores: todo queda en este dispositivo.",
      ),
      h(
        "button",
        { class: "btn primario", type: "button", onClick: () => navegar("/registrar") },
        "＋ Registrar lo primero",
      ),
      h(
        "button",
        { class: "btn enlace", type: "button", onClick: usarDemo },
        "Ver la app con datos de ejemplo",
      ),
    );

  const vista = h(
    "div",
    { class: "inicio" },
    h(
      "header",
      { class: "cabecera" },
      h(
        "div",
        { class: "marca" },
        h("span", { class: "logo", "aria-hidden": "true" }),
        h(
          "div",
          { class: "marca-texto" },
          h("strong", {}, "Transi"),
          h("span", {}, "tu transición, a tu ritmo"),
        ),
      ),
      h(
        "div",
        { class: "cabecera-acciones" },
        h(
          "span",
          { class: "insignia-local", title: "Los datos se guardan en este navegador" },
          "100% local",
        ),
        h(
          "button",
          {
            class: "btn icono",
            type: "button",
            title: "Ajustes",
            "aria-label": "Ajustes",
            onClick: () => navegar("/ajustes"),
          },
          "⚙",
        ),
      ),
    ),
    contenido,
    acciones,
  );

  pintar();
  return vista;
}

function enCurso(datos: Datos): HTMLElement {
  const tratamientos = tratamientosEnCurso(datos);
  return h(
    "section",
    { class: "seccion-en-curso" },
    h(
      "div",
      { class: "seccion-cabecera" },
      h("h2", { class: "seccion-titulo" }, "En curso"),
      h(
        "span",
        { class: "contador" },
        tratamientos.length === 1 ? "1 tratamiento" : `${tratamientos.length} tratamientos`,
      ),
    ),
    h(
      "div",
      { class: "carrusel" },
      ...tratamientos.map((tratamiento: Tratamiento) =>
        h(
          "button",
          {
            class: "tarjeta en-curso",
            type: "button",
            onClick: () => navegar(`/detalle/tratamiento/${tratamiento.id}`),
          },
          h(
            "div",
            { class: "en-curso-fila" },
            h("span", { class: "icono-tarjeta", "aria-hidden": "true" }, "💊"),
            h("span", { class: "etiqueta activo" }, "En curso"),
          ),
          h("strong", {}, tratamiento.nombre),
          h("span", { class: "en-curso-detalle" }, resumenTratamiento(tratamiento) || "Tratamiento"),
          h("span", { class: "tenue" }, duracionTexto(tratamiento.inicio)),
        ),
      ),
    ),
  );
}
