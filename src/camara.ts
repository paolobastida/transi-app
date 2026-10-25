/** Cámara del dispositivo: toma una foto con getUserMedia y devuelve un Blob
 *  que sale por la misma compresión que un archivo elegido desde disco. */

export type Orientacion = "trasera" | "frontal";

export function camaraDisponible(): boolean {
  return (
    typeof navigator !== "undefined" &&
    typeof navigator.mediaDevices?.getUserMedia === "function" &&
    typeof document !== "undefined"
  );
}

/** Traduce los errores del navegador a algo que se lea bien. */
export function mensajeCamara(error: unknown): string {
  if (error instanceof DOMException) {
    if (error.name === "NotAllowedError" || error.name === "SecurityError") {
      return "Necesitamos permiso para usar la cámara. Habilitalo en el navegador y probá de nuevo.";
    }
    if (error.name === "NotFoundError" || error.name === "OverconstrainedError") {
      return "No encontramos una cámara disponible en este dispositivo.";
    }
    if (error.name === "NotReadableError") {
      return "La cámara está siendo usada por otra aplicación.";
    }
  }
  return error instanceof Error ? error.message : "No pudimos acceder a la cámara.";
}

/** Espera a que el video tenga imagen real (videoWidth > 0), con tope de espera. */
function esperarImagen(video: HTMLVideoElement, ms = 4000): Promise<void> {
  if (video.videoWidth > 0) return Promise.resolve();
  return new Promise((resolver, rechazar) => {
    const limpiar = (): void => {
      clearTimeout(temporizador);
      video.removeEventListener("loadeddata", listo);
      video.removeEventListener("error", fallo);
    };
    const listo = (): void => {
      limpiar();
      resolver();
    };
    const fallo = (): void => {
      limpiar();
      rechazar(new Error("La cámara no empezó a emitir imagen."));
    };
    const temporizador = setTimeout(() => {
      limpiar();
      rechazar(new Error("La cámara tardó demasiado en responder."));
    }, ms);
    video.addEventListener("loadeddata", listo, { once: true });
    video.addEventListener("error", fallo, { once: true });
  });
}

export class Camara {
  private flujo: MediaStream | null = null;
  private cancelada = false;
  private orientacion: Orientacion = "trasera";

  get activa(): boolean {
    return this.flujo !== null;
  }

  /** Cierra la cámara, si está abierta. Idempotente: llamarla dos veces no rompe nada. */
  cerrar(): void {
    this.cancelada = true;
    this.flujo?.getTracks().forEach((pista) => pista.stop());
    this.flujo = null;
  }

  /** Pide permiso y enciende la cámara sobre el video dado. */
  async abrir(video: HTMLVideoElement, orientacion: Orientacion = "trasera"): Promise<void> {
    if (!camaraDisponible()) throw new Error("Tu navegador no permite usar la cámara.");
    if (this.flujo) return;

    this.cancelada = false;
    this.orientacion = orientacion;
    const flujo = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: { ideal: orientacion } },
      audio: false,
    });

    // Si se salió de la pantalla mientras se pedía permiso, no dejar la cámara encendida.
    if (this.cancelada) {
      flujo.getTracks().forEach((pista) => pista.stop());
      throw new Error("La cámara se canceló.");
    }

    this.flujo = flujo;
    video.srcObject = flujo;
    await esperarImagen(video);
    await video.play().catch(() => undefined);
  }

  /** ¿Hay más de una cámara para poder ofrecer cambiar de una a otra? */
  async puedeAlternar(): Promise<boolean> {
    if (typeof navigator.mediaDevices?.enumerateDevices !== "function") return false;
    try {
      const dispositivos = await navigator.mediaDevices.enumerateDevices();
      return dispositivos.filter((dispositivo) => dispositivo.kind === "videoinput").length > 1;
    } catch {
      return false;
    }
  }

  /** Enciende la otra cámara (trasera ↔ frontal). Si no hay otra, no hace nada. */
  async alternar(video: HTMLVideoElement): Promise<void> {
    const otra: Orientacion = this.orientacion === "trasera" ? "frontal" : "trasera";
    this.cerrar();
    this.cancelada = false;
    await this.abrir(video, otra);
  }

  /** Captura el cuadro actual del video como JPEG, a la resolución de la cámara. */
  async tomarFoto(video: HTMLVideoElement): Promise<Blob> {
    if (!this.flujo) throw new Error("La cámara no está abierta.");
    const ancho = video.videoWidth;
    const alto = video.videoHeight;
    if (!ancho || !alto) throw new Error("La cámara todavía no tiene imagen.");

    const lienzo = document.createElement("canvas");
    lienzo.width = ancho;
    lienzo.height = alto;
    const contexto = lienzo.getContext("2d");
    if (!contexto) throw new Error("Tu navegador no pudo procesar la imagen.");

    // Sin espejar: lo que se ve en el preview es exactamente lo que se guarda.
    contexto.drawImage(video, 0, 0, ancho, alto);

    return new Promise((resolver, rechazar) => {
      lienzo.toBlob(
        (blob) => (blob ? resolver(blob) : rechazar(new Error("No pudimos capturar la foto."))),
        "image/jpeg",
        0.92,
      );
    });
  }
}
