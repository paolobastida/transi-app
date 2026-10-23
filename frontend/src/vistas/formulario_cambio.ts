import { api } from "../api";
import { archivoABase64, bytesABase64 } from "../archivos";
import { hoy } from "../formato";
import { irAInicio } from "../navegacion";
import type { EntradaAdjunto, Usuario } from "../tipos";
import { aviso, h } from "../ui";

export function vistaFormularioCambio(usuario: Usuario): HTMLElement {
  const adjuntos: EntradaAdjunto[] = [];
  let grabando = false;
  let grabadora: MediaRecorder | null = null;
  let trozos: Blob[] = [];

  const fecha = h("input", { type: "date", value: hoy(), max: hoy() });
  const descripcion = h("textarea", {
    rows: "4",
    placeholder: "¿Qué notaste?",
  });
  const lista = h("div", { class: "adjuntos" });
  const estadoGrabacion = h("p", { class: "grabando" });

  const selectorFoto = h("input", {
    type: "file",
    accept: "image/*",
    style: "display:none",
    onChange: (evento: Event) => void tomarFoto(evento),
  });

  const botonFoto = h(
    "button",
    { type: "button", class: "btn secundario", onClick: () => selectorFoto.click() },
    "📷 Foto",
  );
  const botonVoz = h(
    "button",
    {
      type: "button",
      class: "btn secundario",
      onClick: () => void alternarGrabacion(),
    },
    "🎙 Grabar voz",
  );
  const botonGuardar = h(
    "button",
    { class: "btn primario", onClick: () => void guardar() },
    "Guardar",
  );

  const pintarAdjuntos = () => {
    lista.replaceChildren(
      ...adjuntos.map((adjunto, indice) =>
        h(
          "div",
          { class: "adjunto" },
          h("span", {}, adjunto.tipo === "foto" ? "🖼" : "🎙"),
          h("span", { class: "adjunto-nombre" }, adjunto.nombre),
          h(
            "button",
            {
              type: "button",
              class: "btn icono",
              title: "Quitar",
              onClick: () => {
                adjuntos.splice(indice, 1);
                pintarAdjuntos();
              },
            },
            "×",
          ),
        ),
      ),
    );
  };

  async function tomarFoto(evento: Event) {
    const entrada = evento.target as HTMLInputElement;
    const archivo = entrada.files?.[0];
    if (!archivo) return;
    adjuntos.push({
      tipo: "foto",
      nombre: archivo.name,
      contenido: await archivoABase64(archivo),
    });
    entrada.value = "";
    pintarAdjuntos();
  }

  async function alternarGrabacion() {
    if (!grabando) {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        trozos = [];
        grabadora = new MediaRecorder(stream);
        grabadora.ondataavailable = (evento) => {
          if (evento.data.size > 0) trozos.push(evento.data);
        };
        grabadora.onstop = async () => {
          stream.getTracks().forEach((pista) => pista.stop());
          const tipo = grabadora?.mimeType || "audio/webm";
          const blob = new Blob(trozos, { type: tipo });
          const contenido = bytesABase64(new Uint8Array(await blob.arrayBuffer()));
          adjuntos.push({
            tipo: "audio",
            nombre: tipo.includes("mp4") ? "nota.m4a" : "nota.webm",
            contenido,
          });
          pintarAdjuntos();
        };
        grabadora.start();
        grabando = true;
        botonVoz.textContent = "⏹ Detener";
        estadoGrabacion.textContent = "Grabando…";
      } catch {
        aviso("Necesito permiso para usar el micrófono", true);
      }
    } else {
      grabadora?.stop();
      grabando = false;
      botonVoz.textContent = "🎙 Grabar voz";
      estadoGrabacion.textContent = "";
    }
  }

  async function guardar() {
    if (!descripcion.value.trim() && adjuntos.length === 0) {
      aviso("Escribí algo o agregá una foto o nota de voz", true);
      return;
    }
    botonGuardar.setAttribute("disabled", "true");
    try {
      await api.crearCambio(
        usuario.id,
        fecha.value,
        descripcion.value.trim(),
        adjuntos,
      );
      irAInicio(usuario, 0);
    } catch (error) {
      aviso(String(error), true);
    } finally {
      botonGuardar.removeAttribute("disabled");
    }
  }

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
      h("span", { class: "titulo" }, "Nuevo cambio"),
      h("span"),
    ),
    h(
      "div",
      { class: "contenido" },
      h("label", { class: "campo" }, h("span", {}, "Fecha"), fecha),
      h("label", { class: "campo" }, h("span", {}, "Descripción"), descripcion),
      h("div", { class: "botones-adjunto" }, botonFoto, botonVoz),
      estadoGrabacion,
      lista,
      selectorFoto,
    ),
    h("div", { class: "barra-guardar" }, botonGuardar),
  );
}
