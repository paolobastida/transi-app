import { actualizar, cargar } from "../almacen";
import { alSalir } from "../ciclo_vida";
import { camaraDisponible, Camara, mensajeCamara } from "../camara";
import { hoy } from "../formato";
import { audioDisponible, DURACION_MAXIMA, Grabadora, segundosATexto } from "../grabadora";
import { comprimirImagen } from "../imagen";
import {
  crearCambio,
  guardarEnLista,
  validarCambio,
  type Cambio,
  type EntradaCambio,
} from "../modelo";
import { navegar } from "../rutas";
import { icono } from "../iconos";
import { aviso, h } from "../ui";
import { barraGuardar, cabeceraFormulario, campo } from "./comunes";

function mensajeMicrofono(error: unknown): string {
  if (error instanceof DOMException) {
    if (error.name === "NotAllowedError" || error.name === "SecurityError") {
      return "Necesitamos permiso para usar el micrófono. Habilitalo en el navegador y probá de nuevo.";
    }
    if (error.name === "NotFoundError") {
      return "No encontramos un micrófono conectado.";
    }
  }
  return error instanceof Error ? error.message : "No pudimos acceder al micrófono.";
}

export function vistaFormularioCambio(id?: string): HTMLElement {
  const datos = cargar();
  const existente = id ? datos.cambios.find((cambio) => cambio.id === id) : undefined;

  if (id && !existente) {
    navegar("/");
    return h("div");
  }

  const volver = (): void => (existente ? navegar(`/detalle/cambio/${existente.id}`) : navegar("/"));

  let foto: string | null = existente?.foto ?? null;
  let audio: string | null = existente?.audio ?? null;
  let procesandoAudio = false;
  let vivo = true;

  const fecha = h("input", {
    type: "date",
    value: existente?.fecha ?? hoy(),
    required: true,
  });

  const descripcion = h("textarea", {
    rows: "5",
    placeholder: "¿Qué cambió? ¿Cómo te sentís?",
    required: true,
  });
  descripcion.value = existente?.descripcion ?? "";

  /* Foto ------------------------------------------------------------- */

  const camara = new Camara();
  let canceladaPorUsuario = false;
  const vistaFoto = h("div", { class: "vista-foto" });

  const inputFoto = h("input", {
    type: "file",
    accept: "image/*",
    class: "oculto",
    onChange: (evento: Event) => {
      const archivo = (evento.target as HTMLInputElement).files?.[0];
      // Se limpia el valor para que elegir dos veces el mismo archivo dispare el evento.
      (evento.target as HTMLInputElement).value = "";
      if (archivo) void aplicarFoto(archivo);
    },
  });

  const videoCamara = h("video", {
    class: "camara-video",
    "aria-label": "Vista previa de la cámara",
  });
  // Son propiedades, no atributos: como atributo `muted` no silencia nada.
  videoCamara.playsInline = true;
  videoCamara.muted = true;

  const textoCapturar = h("span", {}, "Tomar foto");
  const botonCapturar = h(
    "button",
    { class: "btn primario", type: "button", onClick: () => void capturar() },
    textoCapturar,
  );
  const botonAlternar = h(
    "button",
    { class: "btn secundario oculto", type: "button", onClick: () => void alternarCamara() },
    "Cambiar cámara",
  );
  const botonCancelarCamara = h(
    "button",
    {
      class: "btn enlace",
      type: "button",
      onClick: () => {
        canceladaPorUsuario = true;
        cerrarCamara();
      },
    },
    "Cancelar",
  );

  const panelCamara = h(
    "div",
    { class: "camara-panel oculto", role: "dialog", "aria-label": "Cámara" },
    h("div", { class: "camara-marco" }, videoCamara),
    h("div", { class: "fila-botones" }, botonCapturar, botonAlternar, botonCancelarCamara),
    h("p", { class: "ayuda" }, "La foto se guarda comprimida, sin salir de este dispositivo."),
  );

  const botonTomarFoto = h(
    "button",
    { class: "btn secundario", type: "button", onClick: () => void abrirCamara() },
    icono("camara"),
    "Tomar foto",
  );

  const botonSubirFoto = h(
    "button",
    { class: "btn secundario", type: "button", onClick: () => inputFoto.click() },
    icono("subir"),
    "Subir foto",
  );

  const botonQuitarFoto = h(
    "button",
    {
      class: "btn peligro chico oculto",
      type: "button",
      onClick: () => {
        foto = null;
        pintarFoto();
      },
    },
    "Quitar foto",
  );

  const pintarFoto = (): void => {
    vistaFoto.replaceChildren(foto ? h("img", { class: "foto-previa", src: foto, alt: "Foto elegida" }) : "");
    botonQuitarFoto.classList.toggle("oculto", !foto);
  };

  function cerrarCamara(devolverFoco = true): void {
    const estabaAbierto = panelCamara.isConnected;
    camara.cerrar();
    panelCamara.classList.add("oculto");
    panelCamara.remove();
    textoCapturar.textContent = "Tomar foto";
    botonCapturar.disabled = false;
    // El `await` de getUserMedia puede seguir pendiente cuando el usuario
    // cancela: sin reactivarlos acá, los botones quedan trabados.
    botonTomarFoto.disabled = false;
    botonSubirFoto.disabled = false;
    if (estabaAbierto && devolverFoco) botonTomarFoto.focus();
  }

  async function abrirCamara(): Promise<void> {
    if (!camaraDisponible()) {
      aviso("Tu navegador no permite usar la cámara. Subí un archivo en su lugar.", true);
      inputFoto.click();
      return;
    }
    botonTomarFoto.disabled = true;
    botonCapturar.disabled = true;
    textoCapturar.textContent = "Pidiendo permiso…";
    canceladaPorUsuario = false;
    panelCamara.classList.remove("oculto");
    document.body.append(panelCamara);
    try {
      await camara.abrir(videoCamara);
      botonAlternar.classList.toggle("oculto", !(await camara.puedeAlternar()));
    } catch (error) {
      cerrarCamara();
      // Si el usuario canceló a propósito, no hay nada que avisar.
      if (!canceladaPorUsuario) aviso(mensajeCamara(error), true);
      return;
    } finally {
      botonTomarFoto.disabled = false;
    }
    botonCapturar.disabled = false;
    textoCapturar.textContent = "Tomar foto";
    botonCapturar.focus();
  }

  async function capturar(): Promise<void> {
    botonCapturar.disabled = true;
    try {
      const blob = await camara.tomarFoto(videoCamara);
      cerrarCamara();
      await aplicarFoto(blob);
    } catch (error) {
      aviso(error instanceof Error ? error.message : "No pudimos tomar la foto.", true);
      botonCapturar.disabled = false;
    }
  }

  async function alternarCamara(): Promise<void> {
    botonAlternar.disabled = true;
    try {
      await camara.alternar(videoCamara);
    } catch (error) {
      cerrarCamara();
      aviso(mensajeCamara(error), true);
      return;
    } finally {
      botonAlternar.disabled = false;
    }
  }

  /** Un solo camino de compresión para la foto de cámara y la del archivo. */
  const aplicarFoto = async (blob: Blob): Promise<void> => {
    botonTomarFoto.disabled = true;
    botonSubirFoto.disabled = true;
    const textoPrevio = botonSubirFoto.textContent;
    botonSubirFoto.textContent = "Procesando…";
    try {
      foto = await comprimirImagen(blob);
      pintarFoto();
    } catch (error) {
      aviso(error instanceof Error ? error.message : "No pudimos procesar la imagen.", true);
      pintarFoto();
    } finally {
      botonTomarFoto.disabled = false;
      botonSubirFoto.disabled = false;
      botonSubirFoto.textContent = textoPrevio;
    }
  };

  /* Nota de voz ------------------------------------------------------ */

  const textoGrabar = h("span", {}, "Grabar nota");
  const botonGrabar = h(
    "button",
    { class: "btn secundario", type: "button", onClick: () => void comenzarGrabacion() },
    icono("microfono"),
    textoGrabar,
  );

  const botonDetener = h(
    "button",
    { class: "btn peligro chico", type: "button", onClick: () => detenerGrabacion() },
    "Detener",
  );

  const tiempo = h("span", { class: "tiempo-grabacion" }, "0:00");
  const panelGrabando = h(
    "div",
    { class: "grabando-panel oculto" },
    h("span", { class: "punto-grabando", "aria-hidden": "true" }),
    h("span", { class: "grabando-texto" }, "Grabando"),
    tiempo,
    botonDetener,
  );

  const reproductor = h("audio", { controls: true, preload: "metadata" });
  const botonQuitarAudio = h(
    "button",
    {
      class: "btn peligro chico",
      type: "button",
      onClick: () => {
        audio = null;
        reproductor.removeAttribute("src");
        pintarAudio();
      },
    },
    "Quitar nota",
  );
  const panelAudio = h("div", { class: "audio-previa oculto" }, reproductor, botonQuitarAudio);

  const pintarAudio = (): void => {
    const grabando = grabadora.activa;
    panelGrabando.classList.toggle("oculto", !grabando);
    panelAudio.classList.toggle("oculto", !(audio && !grabando && !procesandoAudio));
    botonGrabar.classList.toggle("oculto", grabando || Boolean(audio));
    botonGrabar.disabled = procesandoAudio || !audioDisponible();
    textoGrabar.textContent = procesandoAudio ? "Procesando…" : "Grabar nota";

    if (audio) {
      if (reproductor.getAttribute("src") !== audio) reproductor.src = audio;
    } else {
      reproductor.removeAttribute("src");
    }
  };

  const grabadora = new Grabadora({
    alProgreso: (segundos) => {
      tiempo.textContent = segundosATexto(segundos);
      if (segundos >= DURACION_MAXIMA) {
        aviso(`La nota llegó al máximo de ${DURACION_MAXIMA} segundos.`);
        procesandoAudio = true;
        pintarAudio();
      }
    },
    alTerminar: (dataUrl) => {
      if (!vivo) return;
      procesandoAudio = false;
      audio = dataUrl;
      pintarAudio();
    },
    alError: (mensaje) => {
      if (!vivo) return;
      procesandoAudio = false;
      pintarAudio();
      aviso(mensaje, true);
    },
  });

  const comenzarGrabacion = async (): Promise<void> => {
    if (grabadora.activa || procesandoAudio) return;
    if (!audioDisponible()) {
      aviso("Tu navegador no permite grabar audio.", true);
      return;
    }

    botonGrabar.disabled = true;
    textoGrabar.textContent = "Pidiendo permiso…";
    try {
      await grabadora.iniciar();
      tiempo.textContent = "0:00";
      pintarAudio();
    } catch (error) {
      aviso(mensajeMicrofono(error), true);
      pintarAudio();
    } finally {
      botonGrabar.disabled = !audioDisponible();
    }
  };

  const detenerGrabacion = (): void => {
    if (!grabadora.activa) return;
    procesandoAudio = true;
    grabadora.detener();
    pintarAudio();
  };

  panelCamara.addEventListener("keydown", (evento) => {
    if (evento.key === "Escape") {
      evento.preventDefault();
      canceladaPorUsuario = true;
      cerrarCamara();
    }
  });

  alSalir(() => {
    vivo = false;
    grabadora.cancelar();
    // Va en el MISMO alSalir: `alSalir` es un slot único, y registrar otro
    // pisaría la limpieza del micrófono.
    cerrarCamara(false);
  });

  /* Guardar ---------------------------------------------------------- */

  const alGuardar = (evento: SubmitEvent): void => {
    evento.preventDefault();

    if (grabadora.activa) {
      aviso("Detené la grabación antes de guardar.", true);
      return;
    }
    if (procesandoAudio) {
      aviso("Esperá un segundo: estamos guardando la nota de voz.", true);
      return;
    }

    const entrada: EntradaCambio = {
      fecha: fecha.value,
      descripcion: descripcion.value,
      foto,
      audio,
    };

    const error = validarCambio(entrada);
    if (error) {
      aviso(error, true);
      return;
    }

    const limpio = crearCambio(entrada);
    const cambio: Cambio = existente ? { ...limpio, id: existente.id } : limpio;
    const guardado = actualizar((actuales) => ({
      ...actuales,
      cambios: guardarEnLista(actuales.cambios, cambio),
    }));

    if (!guardado) {
      aviso("No hay espacio para guardar. Probá con una foto o nota más chica, o borrá algún registro.", true);
      return;
    }

    aviso(existente ? "Cambio actualizado." : "Cambio guardado.");
    navegar(`/detalle/cambio/${cambio.id}`);
  };

  pintarFoto();
  pintarAudio();

  return h(
    "form",
    { class: "pantalla-formulario", onSubmit: alGuardar },
    cabeceraFormulario(existente ? "Editar cambio" : "Nuevo cambio", volver),
    h(
      "main",
      { class: "contenido" },
      h(
        "section",
        { class: "panel" },
        h("h2", { class: "panel-titulo" }, "El momento"),
        campo("Fecha del cambio", fecha),
        campo("¿Qué cambió?", descripcion, "Escribí lo que quieras recordar de este momento."),
      ),
      h(
        "section",
        { class: "panel" },
        h("h2", { class: "panel-titulo" }, "Adjuntos"),
        h("p", { class: "ayuda panel-ayuda" }, "Son opcionales y quedan guardados en este dispositivo."),
        h(
          "div",
          { class: "campo" },
          h(
            "span",
            { class: "campo-etiqueta" },
            "Foto",
            h("em", { class: "campo-opcional" }, "Opcional"),
          ),
          vistaFoto,
          inputFoto,
          h("div", { class: "fila-botones" }, botonTomarFoto, botonSubirFoto, botonQuitarFoto),
          h("p", { class: "ayuda" }, "Se guarda una versión comprimida."),
        ),
        h(
          "div",
          { class: "campo" },
          h(
            "span",
            { class: "campo-etiqueta" },
            "Nota de voz",
            h("em", { class: "campo-opcional" }, "Opcional"),
          ),
          h("div", { class: "grabadora" }, panelGrabando, panelAudio),
          h("div", { class: "fila-botones" }, botonGrabar),
          h(
            "p",
            { class: "ayuda" },
            audioDisponible()
              ? `Hasta ${DURACION_MAXIMA} segundos.`
              : "Tu navegador no permite grabar audio.",
          ),
        ),
      ),
      h("p", { class: "nota-local" }, "Nada de esto se envía a internet."),
    ),
    barraGuardar(existente ? "Guardar cambios" : "Guardar cambio"),
  );
}
