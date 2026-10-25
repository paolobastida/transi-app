/**
 * Recordatorios de toma.
 *
 * En la app nativa de macOS se programan en el sistema con
 * `UNUserNotificationCenter` (suenan aunque la app esté cerrada). En el
 * navegador no existe esa API, así que se revisan mientras la app está abierta.
 */

import { cargar } from "./almacen";
import { aISO, sumarDias } from "./formato";
import { aviso as avisoEnPantalla } from "./ui";
import { cadenciaDe, esDiaDeAplicacion, fechasDeMedicamento, HORIZONTE_DIAS, type Cadencia } from "./aplicaciones";
import type { Datos, Medicamento } from "./modelo";

/** Minutos después de la hora en los que el aviso sigue siendo útil. */
export const GRACIA_MINUTOS = 3;

const INTERVALO_MS = 20_000;
const RECONCILIACION_MS = 30_000;
const CLAVE_AVISADAS = "transi.recordatorios";
/** El aviso en pantalla dura más que un aviso común: hay que poder leerlo. */
const DURACION_AVISO_MS = 10_000;

export interface Aviso {
  /** Identifica la toma de hoy: `AAAA-MM-DD|medicamento|horario`. */
  clave: string;
  medicamento: Medicamento;
  horario: string;
}

/** Un aviso que el sistema operativo programa y repite todos los días. */
export interface RecordatorioProgramado {
  id: string;
  titulo: string;
  cuerpo: string;
  /** Hora local, 0–23. */
  hora: number;
  /** Minuto local, 0–59. */
  minuto: number;
  /**
   * Días concretos "AAAA-MM-DD" en los que aplica, cuando la frecuencia no es
   * diaria. Si está presente, el sistema agenda avisos puntuales (sin repetir)
   * en vez de uno diario: "cada 7 días" no debe sonar todos los días.
   */
  fechas?: string[];
}

export type PermisoNotificaciones =
  | "no-soportado"
  | "sin-solicitar"
  | "concedido"
  | "denegado";

export interface EstadoRecordatorios {
  /** `true` si el contenedor nativo los programa en el sistema operativo. */
  nativo: boolean;
  permiso: PermisoNotificaciones;
  /** Cuántos avisos diarios tiene agendados el sistema. */
  programados: number;
}

/* ------------------------------------------------------------------ */
/* Lógica pura (probable sin navegador)                                */
/* ------------------------------------------------------------------ */

/** "HH:MM" del momento en zona local. */
export function horaActual(ahora: Date): string {
  const dos = (n: number): string => String(n).padStart(2, "0");
  return `${dos(ahora.getHours())}:${dos(ahora.getMinutes())}`;
}

function minutos(horario: string): number {
  const [hora, minuto] = horario.split(":").map(Number);
  return (hora ?? 0) * 60 + (minuto ?? 0);
}

/** `true` si se toma todos los días: ahí al sistema le alcanza con repetir. */
function esDiaria(cadencia: Cadencia): boolean {
  return cadencia.tipo === "dias" && cadencia.cada === 1;
}

/**
 * `true` si la ocurrencia todavía no pasó. Programar un disparo en el pasado
 * con `repeats: false` haría que el sistema lo entregue de inmediato, al abrir
 * la app, como si fuera un aviso nuevo.
 */
function esFutura(fecha: string, hora: number, minuto: number, referencia: Date): boolean {
  const hoyISO = aISO(referencia);
  if (fecha !== hoyISO) return fecha > hoyISO;
  return hora * 60 + minuto > referencia.getHours() * 60 + referencia.getMinutes();
}

/**
 * Qué tomas debería avisar el sistema ahora mismo.
 * Pura: no repite las claves ya avisadas ni sale del rango de gracia.
 */
export function avisosPendientes(
  datos: Datos,
  ahora: Date,
  avisadas: ReadonlySet<string> = new Set(),
): Aviso[] {
  const fecha = aISO(ahora);
  const ahoraMin = minutos(horaActual(ahora));
  const pendientes: Aviso[] = [];

  for (const tratamiento of datos.tratamientos) {
    // Solo tratamientos en curso: ni futuros ni finalizados.
    if (tratamiento.inicio > fecha) continue;
    if (tratamiento.fin && tratamiento.fin < fecha) continue;

    for (const medicamento of tratamiento.medicamentos) {
      // La frecuencia manda: "cada 7 días" solo avisa cada 7 días.
      if (!esDiaDeAplicacion(tratamiento.inicio, fecha, cadenciaDe(medicamento))) continue;

      for (const horario of medicamento.horarios) {
        const transcurridos = ahoraMin - minutos(horario);
        if (transcurridos < 0 || transcurridos > GRACIA_MINUTOS) continue;
        const clave = `${fecha}|${medicamento.id}|${horario}`;
        if (avisadas.has(clave)) continue;
        pendientes.push({ clave, medicamento, horario });
      }
    }
  }

  return pendientes.sort((a, b) => (a.horario < b.horario ? -1 : a.horario > b.horario ? 1 : 0));
}

/**
 * Texto de un aviso: uno solo o, si varias tomas comparten hora, un único
 * aviso con todos los medicamentos. (En la app nativa el sistema programa
 * cada recordatorio por separado; esto aplica al aviso del navegador.)
 */
export function mensajeGrupo(avisos: Aviso[]): { titulo: string; cuerpo: string } {
  const horario = avisos[0]?.horario ?? "";

  if (avisos.length === 1) {
    const medicamento = avisos[0]?.medicamento;
    return {
      titulo: `Toma de ${medicamento?.nombre ?? ""}`,
      cuerpo: [medicamento?.dosis, `a las ${horario}`].filter(Boolean).join(" · "),
    };
  }

  const nombres = avisos.map((aviso) =>
    aviso.medicamento.dosis ? `${aviso.medicamento.nombre} · ${aviso.medicamento.dosis}` : aviso.medicamento.nombre,
  );
  return { titulo: `${avisos.length} tomas a las ${horario}`, cuerpo: nombres.join(" + ") };
}

/**
 * Arma la lista de avisos diarios que el sistema debe programar.
 *
 * Es pura y determinista: mismo conjunto de datos + referencia, misma lista.
 * El `id` es estable (medicamento + horario), así que reprogramar reemplaza el
 * aviso anterior en vez de duplicarlo.
 */
export function recordatoriosProgramados(
  datos: Datos,
  referencia = new Date(),
): RecordatorioProgramado[] {
  const fecha = aISO(referencia);
  const lista: RecordatorioProgramado[] = [];

  for (const tratamiento of datos.tratamientos) {
    if (tratamiento.inicio > fecha) continue;
    if (tratamiento.fin && tratamiento.fin < fecha) continue;

    for (const medicamento of tratamiento.medicamentos) {
      const diaria = esDiaria(cadenciaDe(medicamento));

      for (const horario of medicamento.horarios) {
        const partes = horario.split(":");
        const hora = Number(partes[0] ?? "");
        const minuto = Number(partes[1] ?? "");
        if (!Number.isInteger(hora) || !Number.isInteger(minuto)) continue;
        if (hora < 0 || hora > 23 || minuto < 0 || minuto > 59) continue;

        // Frecuencia no diaria: el sistema necesita los días concretos. Sin
        // ninguna toma pendiente en el horizonte, no hay nada que agendar.
        const fechas = diaria
          ? undefined
          : fechasDeMedicamento(tratamiento, medicamento, fecha, sumarDias(fecha, HORIZONTE_DIAS)).filter(
              (ocurrencia) => esFutura(ocurrencia, hora, minuto, referencia),
            );
        if (!diaria && !fechas?.length) continue;

        lista.push({
          id: `transi.recordatorio.${medicamento.id}.${horario}`,
          titulo: `Toma de ${medicamento.nombre}`,
          cuerpo: [medicamento.dosis, `a las ${horario}`].filter(Boolean).join(" · "),
          hora,
          minuto,
          ...(fechas ? { fechas } : {}),
        });
      }
    }
  }

  return lista.sort(
    (a, b) => a.hora * 60 + a.minuto - (b.hora * 60 + b.minuto) || a.id.localeCompare(b.id),
  );
}

export interface RecordatorioHoy {
  /** Identifica el medicamento + horario dentro del día. */
  clave: string;
  nombre: string;
  dosis: string | null;
  horario: string;
  /** true si la hora ya pasó hoy. */
  pasado: boolean;
}

/** Los recordatorios de hoy ordenados de menor a mayor hora. Pura. */
export function recordatoriosDeHoy(datos: Datos, ahora = new Date()): RecordatorioHoy[] {
  const fecha = aISO(ahora);
  const ahoraMin = minutos(horaActual(ahora));
  const lista: RecordatorioHoy[] = [];

  for (const tratamiento of datos.tratamientos) {
    if (tratamiento.inicio > fecha) continue;
    if (tratamiento.fin && tratamiento.fin < fecha) continue;

    for (const medicamento of tratamiento.medicamentos) {
      // Igual que los avisos: en días sin toma no hay recordatorio.
      if (!esDiaDeAplicacion(tratamiento.inicio, fecha, cadenciaDe(medicamento))) continue;

      for (const horario of medicamento.horarios) {
        lista.push({
          clave: `${medicamento.id}|${horario}`,
          nombre: medicamento.nombre,
          dosis: medicamento.dosis.trim() || null,
          horario,
          pasado: minutos(horario) < ahoraMin,
        });
      }
    }
  }

  return lista.sort((a, b) => (a.horario < b.horario ? -1 : a.horario > b.horario ? 1 : 0));
}

/* ------------------------------------------------------------------ */
/* Puente con el contenedor nativo (macOS)                             */
/* ------------------------------------------------------------------ */

interface ManejadorNativo {
  postMessage: (mensaje: unknown) => void;
}

interface RespuestaNativa {
  solicitudId?: string;
  ok: boolean;
  permiso?: PermisoNotificaciones;
  programados?: number;
  error?: string;
}

type Resolver = (respuesta: RespuestaNativa) => void;

const esperando = new Map<string, Resolver>();

function handlerNativo(): ManejadorNativo | null {
  if (typeof window === "undefined") return null;
  const webkit = (
    window as unknown as {
      webkit?: { messageHandlers?: { recordatorios?: ManejadorNativo } };
    }
  ).webkit;
  return webkit?.messageHandlers?.recordatorios ?? null;
}

/** `true` si estamos dentro del contenedor nativo con programación del sistema. */
export function soportaRecordatoriosNativos(): boolean {
  return handlerNativo() !== null;
}

declare global {
  interface Window {
    __transiRecordatoriosRecibir?: (json: string) => void;
  }
}

// El contenedor nativo responde a las solicitudes por esta función global.
function recibirRespuesta(json: string): void {
  try {
    const respuesta = JSON.parse(json) as RespuestaNativa;
    if (!respuesta.solicitudId) return;
    const resolver = esperando.get(respuesta.solicitudId);
    if (!resolver) return;
    esperando.delete(respuesta.solicitudId);
    resolver(respuesta);
  } catch {
    // Una respuesta ilegible no debe romper la app.
  }
}

// En Node (tests) no existe `window`: solo registramos el puente en el webview.
if (typeof window !== "undefined") {
  window.__transiRecordatoriosRecibir = recibirRespuesta;
}

function pedirNativo(
  mensaje: Record<string, unknown>,
  tiempoMaximo = 3000,
): Promise<RespuestaNativa> {
  const handler = handlerNativo();
  if (!handler) {
    return Promise.resolve({ ok: false, error: "sin puente nativo" });
  }

  const solicitudId = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  return new Promise((resolver) => {
    esperando.set(solicitudId, resolver);
    handler.postMessage({ ...mensaje, solicitudId });
    // Si el nativo no contesta (app vieja, error), no dejamos la promesa colgada.
    globalThis.setTimeout(() => {
      if (esperando.delete(solicitudId)) {
        resolver({ ok: false, error: "sin respuesta del sistema" });
      }
    }, tiempoMaximo);
  });
}

/* ------------------------------------------------------------------ */
/* Permiso                                                             */
/* ------------------------------------------------------------------ */

export function permisoNotificaciones(): PermisoNotificaciones {
  if (typeof Notification === "undefined") return "no-soportado";
  if (Notification.permission === "granted") return "concedido";
  if (Notification.permission === "denied") return "denegado";
  return "sin-solicitar";
}

/** Pide permiso. Debe llamarse desde una acción del usuario (un clic). */
export async function solicitarPermiso(): Promise<PermisoNotificaciones> {
  if (handlerNativo()) {
    // El usuario puede tardar en responder al diálogo del sistema.
    const respuesta = await pedirNativo({ accion: "permiso" }, 60_000);
    return respuesta.permiso ?? "no-soportado";
  }

  if (typeof Notification === "undefined") return "no-soportado";
  try {
    await Notification.requestPermission();
  } catch {
    // Algunos navegadores viejos no implementan la promesa; seguimos con el estado actual.
  }
  return permisoNotificaciones();
}

/** Estado actual: si es nativo, cuántos avisos tiene agendados el sistema. */
export async function estadoRecordatorios(): Promise<EstadoRecordatorios> {
  if (handlerNativo()) {
    const respuesta = await pedirNativo({ accion: "estado" });
    return {
      nativo: true,
      permiso: respuesta.ok ? (respuesta.permiso ?? "no-soportado") : "no-soportado",
      programados: respuesta.ok ? (respuesta.programados ?? 0) : 0,
    };
  }
  return { nativo: false, permiso: permisoNotificaciones(), programados: 0 };
}

/** Dispara un aviso de prueba en 10 segundos (solo contenedor nativo). */
export async function probarRecordatorio(): Promise<boolean> {
  const respuesta = await pedirNativo({ accion: "probar" }, 60_000);
  return respuesta.ok;
}

/* ------------------------------------------------------------------ */
/* Programación nativa                                                 */
/* ------------------------------------------------------------------ */

let firmaEnviada = "";

/** Envía al sistema la lista actual de avisos diarios. */
export function sincronizarRecordatorios(): void {
  const handler = handlerNativo();
  if (!handler) return;
  const lista = recordatoriosProgramados(cargar());
  firmaEnviada = JSON.stringify(lista);
  handler.postMessage({ accion: "sincronizar", recordatorios: lista });
}

/** Reconcilia solo si los datos cambiaron (barato; no dispara avisos). */
export function sincronizarSiCambio(): void {
  const handler = handlerNativo();
  if (!handler) return;
  const lista = recordatoriosProgramados(cargar());
  const firma = JSON.stringify(lista);
  if (firma === firmaEnviada) return;
  firmaEnviada = firma;
  handler.postMessage({ accion: "sincronizar", recordatorios: lista });
}

/* ------------------------------------------------------------------ */
/* Avisos ya enviados hoy (fallback web)                               */
/* ------------------------------------------------------------------ */

let cache: { fecha: string; claves: Set<string> } | null = null;

function avisadas(): Set<string> {
  const fecha = aISO(new Date());
  if (cache?.fecha === fecha) return cache.claves;
  const claves = new Set<string>();
  try {
    const guardado = localStorage.getItem(CLAVE_AVISADAS);
    const dato = guardado ? (JSON.parse(guardado) as { fecha?: unknown; claves?: unknown }) : null;
    if (dato?.fecha === fecha && Array.isArray(dato.claves)) {
      for (const clave of dato.claves) if (typeof clave === "string") claves.add(clave);
    }
  } catch {
    // Sin localStorage disponible: como mucho repetimos un aviso tras recargar.
  }
  cache = { fecha, claves };
  return claves;
}

function marcarAvisada(clave: string): void {
  const claves = avisadas();
  claves.add(clave);
  try {
    localStorage.setItem(CLAVE_AVISADAS, JSON.stringify({ fecha: cache?.fecha, claves: [...claves] }));
  } catch {
    // Si no se puede persistir, la memoria de la sesión igual evita repetir.
  }
}

/* ------------------------------------------------------------------ */
/* Publicar (fallback web)                                             */
/* ------------------------------------------------------------------ */

function publicar(mensaje: { titulo: string; cuerpo: string }, tag: string): void {
  const { titulo, cuerpo } = mensaje;
  const enPantalla = `${titulo} — ${cuerpo}`;

  if (permisoNotificaciones() === "concedido") {
    try {
      new Notification(titulo, { body: cuerpo, tag, icon: "./icono-192.png" });
      return;
    } catch {
      // Chrome en Android no soporta el constructor: seguimos con el aviso en pantalla.
    }
  }

  // Con permiso pero sin constructor (Android): el service worker puede mostrarla.
  if (permisoNotificaciones() === "concedido" && "serviceWorker" in navigator) {
    navigator.serviceWorker.ready
      .then((registro) => registro.showNotification(titulo, { body: cuerpo, tag }))
      .catch(() => avisoEnPantalla(enPantalla, false, DURACION_AVISO_MS));
    return;
  }

  avisoEnPantalla(enPantalla, false, DURACION_AVISO_MS);
}

/* ------------------------------------------------------------------ */
/* Arranque                                                            */
/* ------------------------------------------------------------------ */

let intervalo: number | null = null;
let reconciliacion: number | null = null;

function revisar(): void {
  const pendientes = avisosPendientes(cargar(), new Date(), avisadas());
  if (pendientes.length === 0) return;

  // Tomas que comparten hora: un solo aviso con todos los medicamentos.
  const porHora = new Map<string, Aviso[]>();
  for (const aviso of pendientes) {
    const grupo = porHora.get(aviso.horario);
    if (grupo) grupo.push(aviso);
    else porHora.set(aviso.horario, [aviso]);
  }

  for (const grupo of porHora.values()) {
    for (const aviso of grupo) marcarAvisada(aviso.clave);
    publicar(mensajeGrupo(grupo), grupo[0]?.clave ?? "avisos");
  }
}

function alVolverseVisible(): void {
  if (document.visibilityState === "visible") sincronizarSiCambio();
}

function alRecuperarFoco(): void {
  sincronizarSiCambio();
}

/** Arranca la programación nativa o, en el navegador, la revisión periódica. */
export function iniciarRecordatorios(): void {
  if (handlerNativo()) {
    if (reconciliacion !== null) return;
    // Primera sincronización + red de seguridad: si otra pestaña/perfil cambió
    // los datos, en ≤30 s se reprograma el sistema. No dispara avisos.
    sincronizarRecordatorios();
    document.addEventListener("visibilitychange", alVolverseVisible);
    window.addEventListener("focus", alRecuperarFoco);
    reconciliacion = window.setInterval(sincronizarSiCambio, RECONCILIACION_MS);
    return;
  }

  if (intervalo !== null) return;
  revisar();
  intervalo = window.setInterval(revisar, INTERVALO_MS);
}

export function detenerRecordatorios(): void {
  if (intervalo !== null) {
    clearInterval(intervalo);
    intervalo = null;
  }
  if (reconciliacion !== null) {
    clearInterval(reconciliacion);
    reconciliacion = null;
    document.removeEventListener("visibilitychange", alVolverseVisible);
    window.removeEventListener("focus", alRecuperarFoco);
  }
}
