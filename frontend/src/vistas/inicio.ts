import { api } from "../api";
import { irACambio, irACuenta, irALogin } from "../navegacion";
import type { Usuario } from "../tipos";
import { aviso, confirmar, h } from "../ui";
import { vistaLineaDeTiempo } from "./linea_de_tiempo";
import { vistaTratamientos } from "./tratamientos";

export function vistaInicio(usuario: Usuario, inicial = 0): HTMLElement {
  let pestana = inicial;

  const chips = h("nav", { class: "pestanas" });
  const contenido = h("div", { class: "contenido-inicio" });
  const acciones = h("div", { class: "fab-contenedor" });

  function botonPestana(texto: string, indice: number): HTMLElement {
    return h(
      "button",
      {
        class: `pestana ${pestana === indice ? "activa" : ""}`,
        onClick: () => {
          pestana = indice;
          pintar();
        },
      },
      texto,
    );
  }

  const pintar = () => {
    chips.replaceChildren(
      botonPestana("Línea de tiempo", 0),
      botonPestana("Tratamientos", 1),
    );
    contenido.replaceChildren(
      pestana === 0 ? vistaLineaDeTiempo(usuario) : vistaTratamientos(usuario),
    );
    acciones.replaceChildren(
      pestana === 0
        ? h(
            "button",
            { class: "fab", onClick: () => irACambio(usuario) },
            "+ Registrar cambio",
          )
        : h("span"),
    );
  };

  const salir = async () => {
    const seguro = confirmar(
      "¿Cerrar sesión? Los datos locales de salud se borran del dispositivo (quedan en tu respaldo).",
    );
    if (!seguro) return;
    try {
      await api.salir();
      irALogin();
    } catch (error) {
      aviso(String(error), true);
    }
  };

  const vista = h(
    "div",
    { class: "inicio" },
    h(
      "header",
      { class: "cabecera" },
      h(
        "div",
        { class: "marca" },
        h("span", { class: "logo" }),
        h("span", { class: "titulo" }, "Transi"),
      ),
      h(
        "div",
        { class: "cabecera-acciones" },
        h(
          "button",
          {
            class: "btn icono",
            title: "Cuenta y respaldo",
            onClick: () => irACuenta(usuario),
          },
          "☁",
        ),
        h(
          "button",
          {
            class: "btn icono",
            title: `Cerrar sesión (${usuario.email})`,
            onClick: () => void salir(),
          },
          "⏻",
        ),
      ),
    ),
    chips,
    contenido,
    acciones,
  );

  pintar();
  return vista;
}
