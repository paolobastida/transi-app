import { navegar } from "../rutas";
import { icono } from "../iconos";
import { h } from "../ui";
import { cabeceraVista } from "./comunes";

/** Ayuda en lenguaje simple, pensada para quien abre la app por primera vez. */
export function vistaAyuda(): HTMLElement {
  return h(
    "div",
    { class: "pantalla-detalle" },
    cabeceraVista("Ayuda", () => navegar("/")),
    h(
      "main",
      { class: "contenido" },
      h(
        "section",
        { class: "tarjeta ficha" },
        h("h2", {}, "Transi, en simple"),
        h(
          "p",
          { class: "sub" },
          "Es un cuaderno privado para anotar tus tratamientos y los cambios que notes. " +
            "No hace falta crear una cuenta y nada de lo que cargás se envía a internet.",
        ),
        h(
          "ol",
          { class: "ayuda-pasos", "aria-label": "Primeros pasos en Transi" },
          paso("1", "Anotá lo que tomás", "Medicamentos, dosis, fechas y profesional."),
          paso(
            "2",
            "Registrá cómo te sentís",
            "Un cambio puede ser físico, emocional o simplemente algo que querés recordar.",
          ),
          paso("3", "Llevate tus datos", "Exportá un respaldo cuando quieras desde Ajustes."),
        ),
      ),
      h(
        "section",
        { class: "tarjeta ficha" },
        h("h2", {}, "¿Qué es un tratamiento?"),
        h(
          "p",
          { class: "sub" },
          "Es lo que estás tomando o haciendo por tu salud: hormonas, medicación, controles. " +
            "Podés cargar varios medicamentos en un mismo tratamiento, cada uno con su dosis y sus horarios.",
        ),
      ),
      h(
        "section",
        { class: "tarjeta ficha" },
        h("h2", {}, "¿Y un cambio?"),
        h(
          "p",
          { class: "sub" },
          "Es cualquier cosa que notes y quieras guardar: un cambio en tu cuerpo, en tu ánimo, " +
            "una primera vez o una sensación. Podés sumarle una foto o una nota de voz.",
        ),
      ),
      h(
        "section",
        { class: "tarjeta ficha" },
        h("h2", {}, "Tus datos, solo tuyos"),
        h(
          "p",
          { class: "sub" },
          "Todo se guarda en este dispositivo. No hay servidores con tus registros ni copias en la nube. " +
            "Para no perderlos, exportá un respaldo desde Ajustes y guardalo donde quieras.",
        ),
      ),
      h(
        "section",
        { class: "tarjeta ficha" },
        h("h2", {}, "Recordatorios"),
        h(
          "p",
          { class: "sub" },
          "Cuando cargás un medicamento podés agregar horarios. En la app de macOS los avisos suenan " +
            "aunque Transi esté cerrada; en el navegador, mientras la app esté abierta.",
        ),
      ),
      h(
        "section",
        { class: "tarjeta ficha" },
        h("h2", {}, "Cuenta opcional"),
        h(
          "p",
          { class: "sub" },
          "Entrar con una cuenta (Google, Facebook o Apple) solo sirve para separar tus datos por perfil " +
            "en este dispositivo. Es opcional: sin cuenta, Transi funciona igual y el proveedor no recibe tus registros.",
        ),
      ),
      h(
        "section",
        { class: "tarjeta ficha" },
        h("h2", {}, "Si algo no se ve bien"),
        h(
          "p",
          { class: "sub" },
          "Probá recargar la app. Si el problema sigue, revisá que el navegador permita guardar datos " +
            "para este sitio. Tus registros anteriores pueden seguir en Ajustes, en la sección de respaldos.",
        ),
      ),
      h(
        "p",
        { class: "nota-local" },
        "Transi no reemplaza un historial clínico ni es consejo médico. " +
          "Si tenés dudas sobre tu salud, consultá con un profesional.",
      ),
      h(
        "div",
        { class: "fila-botones" },
        h(
          "button",
          { class: "btn primario", type: "button", onClick: () => navegar("/") },
          icono("atras"),
          "Volver al inicio",
        ),
        h(
          "button",
          { class: "btn secundario", type: "button", onClick: () => navegar("/ajustes") },
          icono("ajustes"),
          "Ir a Ajustes",
        ),
      ),
    ),
  );
}

function paso(numero: string, titulo: string, detalle: string): HTMLElement {
  return h(
    "li",
    { class: "ayuda-paso" },
    h("span", { class: "ayuda-paso-numero", "aria-hidden": "true" }, numero),
    h(
      "div",
      { class: "ayuda-paso-texto" },
      h("strong", {}, titulo),
      h("span", {}, detalle),
    ),
  );
}
