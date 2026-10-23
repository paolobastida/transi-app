/** Notas de voz: graba con MediaRecorder y devuelve un data URL listo para guardar. */

export const DURACION_MAXIMA = 60; // segundos
const BITRATE = 32_000;

export interface OpcionesGrabadora {
  alProgreso: (segundos: number) => void;
  alTerminar: (audio: string) => void;
  alError: (mensaje: string) => void;
}

export function audioDisponible(): boolean {
  return (
    typeof MediaRecorder !== "undefined" &&
    typeof navigator !== "undefined" &&
    typeof navigator.mediaDevices?.getUserMedia === "function"
  );
}

function tipoPreferido(): string | undefined {
  if (typeof MediaRecorder === "undefined" || typeof MediaRecorder.isTypeSupported !== "function") {
    return undefined;
  }
  const tipos = ["audio/mp4", "audio/webm;codecs=opus", "audio/webm", "audio/ogg;codecs=opus"];
  return tipos.find((tipo) => MediaRecorder.isTypeSupported(tipo));
}

function blobADataUrl(blob: Blob): Promise<string> {
  return new Promise((resolver, rechazar) => {
    const lector = new FileReader();
    lector.onload = () => resolver(String(lector.result));
    lector.onerror = () => rechazar(new Error("No pudimos leer la grabación."));
    lector.readAsDataURL(blob);
  });
}

export function segundosATexto(segundos: number): string {
  const minutos = Math.floor(segundos / 60);
  return `${minutos}:${String(segundos % 60).padStart(2, "0")}`;
}

export class Grabadora {
  private flujo: MediaStream | null = null;
  private grabador: MediaRecorder | null = null;
  private trozos: Blob[] = [];
  private intervalo: number | null = null;
  private segundos = 0;
  private cancelada = false;

  constructor(private readonly opciones: OpcionesGrabadora) {}

  get activa(): boolean {
    return this.grabador?.state === "recording";
  }

  async iniciar(): Promise<void> {
    if (!audioDisponible()) {
      throw new Error("Tu navegador no permite grabar audio.");
    }
    if (this.grabador) return;

    this.cancelada = false;
    const flujo = await navigator.mediaDevices.getUserMedia({ audio: true });

    // Si se salió de la pantalla mientras se pedía permiso, no encender el micrófono.
    if (this.cancelada) {
      flujo.getTracks().forEach((pista) => pista.stop());
      throw new Error("La grabación se canceló.");
    }

    const tipo = tipoPreferido();
    const configuracion: MediaRecorderOptions = { audioBitsPerSecond: BITRATE };
    if (tipo) configuracion.mimeType = tipo;

    let grabador: MediaRecorder;
    try {
      grabador = new MediaRecorder(flujo, configuracion);
    } catch {
      flujo.getTracks().forEach((pista) => pista.stop());
      throw new Error("Tu navegador no pudo iniciar la grabación.");
    }

    this.flujo = flujo;
    this.grabador = grabador;
    this.trozos = [];
    this.segundos = 0;

    grabador.ondataavailable = (evento) => {
      if (evento.data.size > 0) this.trozos.push(evento.data);
    };

    grabador.onstop = () => {
      const tipoFinal = grabador.mimeType || tipo || "audio/webm";
      const trozos = this.trozos;
      const cancelada = this.cancelada;
      this.limpiar();

      if (cancelada) return;
      if (trozos.length === 0) {
        this.opciones.alError("No se grabó audio. Probá de nuevo.");
        return;
      }

      void blobADataUrl(new Blob(trozos, { type: tipoFinal }))
        .then((audio) => {
          if (audio.length > 1_500_000) {
            this.opciones.alError("La nota es demasiado larga. Probá con una más corta.");
            return;
          }
          this.opciones.alTerminar(audio);
        })
        .catch(() => this.opciones.alError("No pudimos guardar la nota de voz."));
    };

    grabador.start(250);
    this.intervalo = window.setInterval(() => {
      this.segundos += 1;
      this.opciones.alProgreso(this.segundos);
      if (this.segundos >= DURACION_MAXIMA) this.detener();
    }, 1000);
  }

  detener(): void {
    if (this.grabador && this.grabador.state !== "inactive") {
      this.grabador.stop();
    }
  }

  cancelar(): void {
    this.cancelada = true;
    this.detener();
    this.limpiar();
  }

  private limpiar(): void {
    if (this.intervalo !== null) {
      clearInterval(this.intervalo);
      this.intervalo = null;
    }
    this.flujo?.getTracks().forEach((pista) => pista.stop());
    this.flujo = null;
    this.grabador = null;
  }
}
