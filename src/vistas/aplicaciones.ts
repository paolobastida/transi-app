import { cargar } from "../almacen";
import {
  agruparPorDia,
  aplicacionesHoy,
  aplicacionesProximas,
  aplicacionesRecientes,
  frecuenciaInterpretable,
  type Aplicacion,
  type GrupoDia,
} from "../aplicaciones";
import { fechaCorta, hoy, sumarDias } from "../formato";
import { icono } from "../iconos";
import { tituloTratamiento } from "../modelo";
import { navegar } from "../rutas";
import { h, vacio } from "../ui";
import { cabeceraVista } from "./comunes";

/** Días que mira la vista hacia adelante y hacia atrás. */
const PROXIMOS_DIAS = 14;
const RECIENTES_DIAS = 7;

export function vistaAplicaciones(): HTMLElement {
  const datos = cargar();
  const fecha = hoy();

  const hoyLista = aplicacionesHoy(datos, fecha);
  const proximas = aplicacionesProximas(datos, fecha, PROXIMOS_DIAS);
  const recientes = aplicacionesRecientes(datos, fecha, RECIENTES_DIAS);

  const sinTratamientos = datos.tratamientos.length === 0;
  const sinAplicaciones = hoyLista.length + proximas.length + recientes.length === 0;

  const encabezadoDia = (dia: string): string => {
    if (dia === fecha) return `Hoy · ${fechaCorta(dia)}`;
    if (dia === sumarDias(fecha, 1)) return `Mañana · ${fechaCorta(dia)}`;
    if (dia === sumarDias(fecha, -1)) return `Ayer · ${fechaCorta(dia)}`;
    return fechaCorta(dia);
  };

  /** Riel con un encabezado por día. */
  const riel = (grupos: GrupoDia[], masRecientePrimero = false): HTMLElement => {
    const contenedor = h("div", { class: "linea-tiempo" });
    const orden = masRecientePrimero ? [...grupos].reverse() : grupos;
    for (const grupo of orden) {
      contenedor.append(h("h3", { class: "mes" }, encabezadoDia(grupo.fecha)));
      for (const aplicacion of grupo.aplicaciones) contenedor.append(fila(aplicacion));
    }
    return contenedor;
  };

  const seccion = (titulo: string, ayuda: string, cuerpo: HTMLElement): HTMLElement =>
    h(
      "section",
      { class: "bloque-aplicaciones" },
      h(
        "div",
        { class: "seccion-cabecera" },
        h(
          "div",
          { class: "seccion-texto" },
          h("h2", { class: "seccion-titulo" }, titulo),
          h("p", { class: "seccion-ayuda" }, ayuda),
        ),
      ),
      cuerpo,
    );

  const registrar = (): void => navegar("/tratamiento");

  let cuerpo: HTMLElement;
  if (sinTratamientos) {
    cuerpo = vacio("calendario", "Todavía no registraste tratamientos.", [
      h("button", { class: "btn primario", type: "button", onClick: registrar }, icono("mas"), "Registrar un tratamiento"),
    ]);
  } else if (sinAplicaciones) {
    cuerpo = vacio(
      "calendario",
      `No hay aplicaciones entre hace ${RECIENTES_DIAS} días y los próximos ${PROXIMOS_DIAS}.`,
      [
        h("button", { class: "btn secundario", type: "button", onClick: registrar }, "Ver mis tratamientos"),
      ],
    );
  } else {
    const bloques: HTMLElement[] = [];

    if (hoyLista.length > 0) {
      bloques.push(
        seccion(
          "Hoy",
          hoyLista.length === 1 ? "1 aplicación" : `${hoyLista.length} aplicaciones`,
          h("div", { class: "linea-tiempo" }, ...hoyLista.map(fila)),
        ),
      );
    } else {
      bloques.push(h("p", { class: "aplicaciones-sin-hoy" }, "Hoy no tenés aplicaciones programadas."));
    }

    if (proximas.length > 0) {
      bloques.push(
        seccion(
          "Próximas",
          `Los próximos ${PROXIMOS_DIAS} días`,
          riel(agruparPorDia(proximas)),
        ),
      );
    }

    if (recientes.length > 0) {
      bloques.push(
        seccion(
          "Recientes",
          `Los últimos ${RECIENTES_DIAS} días`,
          riel(agruparPorDia(recientes), true),
        ),
      );
    }

    const sinInterpretar = [
      ...new Set(
        datos.tratamientos
          .flatMap((tratamiento) => tratamiento.medicamentos)
          .filter((medicamento) => !frecuenciaInterpretable(medicamento))
          .map((medicamento) => medicamento.nombre.trim())
          .filter(Boolean),
      ),
    ];

    if (sinInterpretar.length > 0) {
      bloques.push(
        h(
          "p",
          { class: "nota-local" },
          `No supimos leer la frecuencia de ${unir(sinInterpretar)}: se muestra una aplicación por día. ` +
            `Editá el tratamiento y usá un formato como "cada 7 días".`,
        ),
      );
    }

    bloques.push(
      h(
        "p",
        { class: "pie" },
        `Los recordatorios se programan según la frecuencia de cada medicamento: si es cada 7 días, ` +
          `suenan cada 7 días.`,
      ),
    );

    cuerpo = h("div", { class: "aplicaciones" }, ...bloques);
  }

  return h(
    "div",
    { class: "pantalla-detalle" },
    cabeceraVista("Aplicaciones", () => navegar("/")),
    h("main", { class: "contenido" }, cuerpo),
  );
}

/** Una fila del riel: la aplicación y a qué tratamiento pertenece. */
function fila(aplicacion: Aplicacion): HTMLElement {
  const { medicamento, tratamiento, horario } = aplicacion;
  const detalle = [horario ?? "Sin hora", medicamento.dosis.trim()].filter(Boolean).join(" · ");
  const dia = String(Number(aplicacion.fecha.slice(8, 10)));

  // Con un solo medicamento el nombre del tratamiento es el mismo: repetirlo
  // solo alarga la fila sin aportar nada.
  const nombreTratamiento = tituloTratamiento(tratamiento);
  const contexto = nombreTratamiento === medicamento.nombre ? null : nombreTratamiento;

  return h(
    "div",
    { class: "evento-fila" },
    h(
      "div",
      { class: "riel", "aria-hidden": "true" },
      h("span", { class: "dia tratamiento" }, dia),
    ),
    h(
      "button",
      {
        class: "tarjeta evento",
        type: "button",
        onClick: () => navegar(`/detalle/tratamiento/${tratamiento.id}`),
      },
      h("div", { class: "icono-tarjeta azul" }, icono("pildora")),
      h(
        "div",
        { class: "fila-texto" },
        h("strong", {}, medicamento.nombre),
        h("span", {}, detalle),
        contexto ? h("span", { class: "aplicacion-tratamiento" }, contexto) : null,
      ),
    ),
  );
}

/** "A, B y C" para nombrar medicamentos en un texto. */
function unir(nombres: string[]): string {
  if (nombres.length === 1) return nombres[0] as string;
  return `${nombres.slice(0, -1).join(", ")} y ${nombres.at(-1)}`;
}
