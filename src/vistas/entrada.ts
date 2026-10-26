import { importarDatosAnonimos, entrarConPerfil, omitirAcceso, perfilActual } from "../auth";
import { montarProveedores } from "../botones_cuenta";
import { icono } from "../iconos";
import { nombreVisible, type Perfil } from "../perfil";
import { sincronizarRecordatorios } from "../recordatorios";
import { navegar } from "../rutas";
import { aviso, confirmar, h } from "../ui";

export function vistaEntrada(): HTMLElement {
  if (perfilActual()) {
    navegar("/");
    return h("div");
  }

  const seguirSinCuenta = (): void => {
    omitirAcceso();
    navegar("/");
  };

  const alEntrar = (perfil: Perfil): void => {
    const resultado = entrarConPerfil(perfil);

    if (resultado.cuentaVacia && resultado.hayAnonimos) {
      const mensaje =
        `La cuenta de ${perfil.email} no tiene registros en este dispositivo. ` +
        "¿Querés copiar los que ya tenías sin cuenta?";
      if (confirmar(mensaje) && !importarDatosAnonimos()) {
        aviso("No pudimos copiar los registros sin cuenta.", true);
      }
    }

    sincronizarRecordatorios();
    aviso(`Entraste con ${nombreVisible(perfil)}.`);
    navegar("/");
  };

  const proveedores = h("div", { class: "cuenta-contenedor" });
  montarProveedores(proveedores, {
    alEntrar,
    alError: (mensaje: string) => aviso(mensaje, true),
  });

  return h(
    "div",
    { class: "pantalla-entrada" },
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
      ),
    ),
    h(
      "main",
      { class: "entrada-contenido" },
      h(
        "section",
        { class: "tarjeta entrada-tarjeta" },
        h("span", { class: "logo grande", "aria-hidden": "true" }),
        h("span", { class: "eyebrow" }, "Tu espacio privado"),
        h("h1", {}, "Entrá o creá tu espacio"),
        h(
          "p",
          { class: "entrada-bajada" },
          "Entrá con tu email o con una cuenta de Google o Apple, si están disponibles. " +
            "La cuenta solo separa tus datos en este dispositivo: tus registros no se envían a ningún servidor.",
        ),
        proveedores,
        h(
          "div",
          { class: "entrada-seguir" },
          h(
            "button",
            { class: "btn secundario", type: "button", onClick: seguirSinCuenta },
            "Seguir sin cuenta",
          ),
        ),
        h(
          "p",
          { class: "nota-local" },
          "Sin cuenta también funciona: tus registros quedan solo en este dispositivo.",
        ),
      ),
    ),
  );
}
