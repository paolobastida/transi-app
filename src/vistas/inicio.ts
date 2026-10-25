import { cargar, guardar, respaldoRoto } from "../almacen";
import { duracionTexto } from "../formato";
import {
  datosDemo,
  resumenTratamiento,
  tituloTratamiento,
  tratamientosEnCurso,
  type Datos,
  type Filtro,
  type Tratamiento,
} from "../modelo";
import { navegar } from "../rutas";
import { icono, type NombreIcono } from "../iconos";
import { perfilActual } from "../auth";
import { iniciales, nombreVisible } from "../perfil";
import { recordatoriosDeHoy } from "../recordatorios";
import { aviso, h } from "../ui";
import { vistaLineaDeTiempo } from "./linea_de_tiempo";

export function vistaInicio(filtroInicial: Filtro = "todo"): HTMLElement {
  const datos = cargar();
  const perfil = perfilActual();
  let filtro = filtroInicial;

  const contenido = h("main", { class: "contenido-inicio" });
  const acciones = h("div", { class: "fab-contenedor" });

  const botonFiltro = (texto: string, valor: Filtro): HTMLElement =>
    h(
      "button",
      {
        class: `chip-filtro ${filtro === valor ? "activa" : ""}`,
        type: "button",
        "aria-pressed": filtro === valor ? "true" : "false",
        onClick: () => {
          filtro = valor;
          pintar();
        },
      },
      texto,
    );

  const pintar = (): void => {
    if (datos.tratamientos.length === 0 && datos.cambios.length === 0) {
      contenido.classList.add("sin-en-curso");
      contenido.replaceChildren(bienvenida());
      acciones.replaceChildren();
      return;
    }

    const activos = tratamientosEnCurso(datos);
    contenido.classList.toggle("sin-en-curso", activos.length === 0);
    contenido.replaceChildren(
      ...(activos.length ? [enCurso(datos)] : []),
      ...recordatoriosDeInicio(datos),
      h(
        "div",
        { class: "filtros" },
        h(
          "div",
          { class: "filtros-texto" },
          h("h2", { class: "seccion-titulo" }, "Tu historia"),
          h("p", { class: "filtros-ayuda" }, "Del registro más nuevo al más viejo."),
        ),
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
        h("span", { class: "fab-icono" }, icono("mas")),
        "Anotar",
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
      h("span", { class: "eyebrow" }, "Privado por diseño"),
      h("h1", {}, "Tu transición, a tu ritmo"),
      h(
        "p",
        {},
        "Registrá tus tratamientos y los cambios que notes, en un solo lugar. " +
          "Sin cuentas obligatorias ni servidores de datos: todo queda en este dispositivo.",
      ),
      // Sin esto, la pantalla vacía haría creer que los datos desaparecieron solos.
      respaldoRoto() !== null
        ? h(
            "div",
            { class: "aviso-roto", role: "alert" },
            h("strong", {}, "No pudimos leer tu respaldo."),
            h(
              "span",
              {},
              "Tus registros anteriores no se perdieron: guardamos una copia aparte. " +
                "Recuperala desde Ajustes antes de cargar registros nuevos.",
            ),
            h(
              "button",
              { class: "btn secundario chico", type: "button", onClick: () => navegar("/ajustes") },
              "Ir a Ajustes",
            ),
          )
        : null,
      h(
        "ol",
        { class: "bienvenida-pasos", "aria-label": "Cómo funciona Transi" },
        paso("1", "Anotá lo que tomás", "Medicamentos, dosis y fechas."),
        paso("2", "Registrá tus cambios", "Con una foto o nota de voz si querés."),
        paso("3", "Llevate tus datos", "Exportalos cuando quieras."),
      ),
      h(
        "button",
        { class: "btn primario", type: "button", onClick: () => navegar("/registrar") },
        icono("mas"),
        "Anotar mi primer registro",
      ),
      h(
        "div",
        { class: "bienvenida-enlaces" },
        h(
          "button",
          { class: "btn enlace", type: "button", onClick: usarDemo },
          "Probar con datos de ejemplo",
        ),
        h(
          "button",
          { class: "btn enlace", type: "button", onClick: () => navegar("/ayuda") },
          "¿Cómo funciona?",
        ),
        h(
          "button",
          { class: "btn enlace", type: "button", onClick: () => navegar("/ajustes") },
          "Entrar con Google, Apple o Facebook",
        ),
      ),
      h(
        "div",
        { class: "bienvenida-sellos" },
        sello("candado", "Cuentas opcionales"),
        sello("check", "100% en tu dispositivo"),
        sello("check", "Exportable cuando quieras"),
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
        perfil
          ? h(
              "button",
              {
                class: "btn avatar-boton",
                type: "button",
                title: `Cuenta de ${nombreVisible(perfil)}`,
                "aria-label": `Cuenta de ${nombreVisible(perfil)}`,
                onClick: () => navegar("/ajustes"),
              },
              iniciales(perfil),
            )
          : h(
              "span",
              { class: "insignia-local", title: "Los datos se guardan en este navegador" },
              icono("candado"),
              "100% local",
            ),
        h(
          "button",
          {
            class: "btn icono",
            type: "button",
            title: "Aplicaciones",
            "aria-label": "Aplicaciones",
            onClick: () => navegar("/aplicaciones"),
          },
          icono("calendario"),
        ),
        h(
          "button",
          {
            class: "btn icono",
            type: "button",
            title: "Ayuda",
            "aria-label": "Ayuda",
            onClick: () => navegar("/ayuda"),
          },
          icono("ayuda"),
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
          icono("ajustes"),
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
      h(
        "div",
        { class: "seccion-texto" },
        h("h2", { class: "seccion-titulo" }, "En curso"),
        h("p", { class: "seccion-ayuda" }, "Lo que estás tomando ahora"),
      ),
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
            h("span", { class: "icono-tarjeta azul" }, icono("pildora")),
            h("span", { class: "etiqueta activo" }, "En curso"),
          ),
          h("strong", {}, tituloTratamiento(tratamiento)),
          h("span", { class: "en-curso-detalle" }, resumenTratamiento(tratamiento) || "Tratamiento"),
          h("span", { class: "tenue" }, icono("reloj"), duracionTexto(tratamiento.inicio)),
        ),
      ),
    ),
  );
}

/** Los recordatorios de hoy, con el próximo resaltado. Vacío si no hay ninguno. */
function recordatoriosDeInicio(datos: Datos): HTMLElement[] {
  const delDia = recordatoriosDeHoy(datos);
  if (delDia.length === 0) return [];

  const proximo = delDia.find((item) => !item.pasado);

  return [
    h(
      "section",
      { class: "seccion-recordatorios" },
      h(
        "div",
        { class: "seccion-cabecera" },
        h(
          "div",
          { class: "seccion-texto" },
          h("h2", { class: "seccion-titulo" }, "Recordatorios de hoy"),
          h(
            "p",
            { class: "seccion-ayuda" },
            proximo
              ? `El próximo: ${proximo.nombre} a las ${proximo.horario}`
              : "Ya pasaron todos por hoy",
          ),
        ),
        h("span", { class: "contador" }, delDia.length === 1 ? "1 toma" : `${delDia.length} tomas`),
      ),
      h(
        "ul",
        { class: "lista-recordatorios" },
        ...delDia.map((item) =>
          h(
            "li",
            {
              class: `recordatorio-hoy ${item.pasado ? "pasado" : ""} ${
                proximo && proximo.clave === item.clave ? "proximo" : ""
              }`.trim(),
            },
            h("span", { class: "recordatorio-hora" }, item.horario),
            h(
              "div",
              { class: "recordatorio-info" },
              h("strong", {}, item.nombre),
              item.dosis ? h("span", {}, item.dosis) : null,
            ),
            proximo && proximo.clave === item.clave
              ? h("span", { class: "etiqueta activo" }, "Próximo")
              : null,
          ),
        ),
      ),
    ),
  ];
}

function sello(nombre: NombreIcono, texto: string): HTMLElement {
  return h("span", { class: "sello" }, icono(nombre), texto);
}

function paso(numero: string, titulo: string, detalle: string): HTMLElement {
  return h(
    "li",
    { class: "bienvenida-paso" },
    h("span", { class: "bienvenida-paso-numero", "aria-hidden": "true" }, numero),
    h(
      "span",
      { class: "bienvenida-paso-texto" },
      h("strong", {}, titulo),
      h("span", {}, detalle),
    ),
  );
}
