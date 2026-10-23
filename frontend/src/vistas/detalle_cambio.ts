import { api } from "../api";
import { base64ABlob, mimeDeAudio, mimeDeFoto } from "../archivos";
import { fechaTexto } from "../formato";
import { irAInicio } from "../navegacion";
import type { Adjunto, Cambio, Usuario } from "../tipos";
import { aviso, confirmar, h } from "../ui";

export function vistaDetalleCambio(usuario: Usuario, cambio: Cambio): HTMLElement {
  const desactivar = async () => {
    if (!confirmar("¿Ocultar este cambio? No se borra: deja de mostrarse.")) return;
    try {
      await api.desactivarCambio(cambio.id, usuario.id);
      irAInicio(usuario, 0);
    } catch (error) {
      aviso(String(error), true);
    }
  };

  return h(
    "div",
    { class: "pantalla-formulario" },
    h(
      "header",
      { class: "cabecera" },
      h(
        "button",
        { class: "btn icono", title: "Volver", onClick: () => irAInicio(usuario, 0) },
        "‹",
      ),
      h("span", { class: "titulo" }, "Cambio"),
      h(
        "button",
        {
          class: "btn icono",
          title: "Ocultar cambio",
          onClick: () => void desactivar(),
        },
        "🗑",
      ),
    ),
    h(
      "div",
      { class: "contenido" },
      h("h2", { class: "fecha-detalle" }, fechaTexto(cambio.fecha)),
      cambio.descripcion
        ? h("p", { class: "descripcion" }, cambio.descripcion)
        : null,
      ...cambio.adjuntos.map((adjunto) =>
        adjunto.tipo === "foto" ? foto(adjunto) : audio(adjunto),
      ),
    ),
  );
}

function foto(adjunto: Adjunto): HTMLElement {
  const url = URL.createObjectURL(
    base64ABlob(adjunto.contenido, mimeDeFoto(adjunto.nombre)),
  );
  return h("img", {
    class: "foto-detalle",
    src: url,
    alt: adjunto.nombre,
  });
}

function audio(adjunto: Adjunto): HTMLElement {
  const url = URL.createObjectURL(
    base64ABlob(adjunto.contenido, mimeDeAudio(adjunto.nombre)),
  );
  return h(
    "div",
    { class: "audio-detalle" },
    h("span", {}, "Nota de voz"),
    h("audio", { controls: "true", src: url }),
  );
}
