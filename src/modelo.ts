/** Modelo de datos de Transi. Sin usuarios, sin servidor: todo vive en el dispositivo. */

import { hoy, restarMeses, sumarDias } from "./formato";

export interface Tratamiento {
  id: string;
  nombre: string;
  dosis: string;
  frecuencia: string;
  inicio: string;
  fin: string | null;
  profesional: string | null;
}

export interface Cambio {
  id: string;
  fecha: string;
  descripcion: string;
  foto: string | null;
}

export interface Datos {
  version: 2;
  tratamientos: Tratamiento[];
  cambios: Cambio[];
}

export type Filtro = "todo" | "tratamientos" | "cambios";

export type Evento =
  | { tipo: "tratamiento"; fecha: string; tratamiento: Tratamiento }
  | { tipo: "cambio"; fecha: string; cambio: Cambio };

export interface EntradaTratamiento {
  nombre: string;
  dosis: string;
  frecuencia: string;
  inicio: string;
  fin: string | null;
  profesional: string | null;
}

export interface EntradaCambio {
  fecha: string;
  descripcion: string;
  foto: string | null;
}

export const DATOS_VACIOS: Datos = { version: 2, tratamientos: [], cambios: [] };

export function datosVacios(): Datos {
  return { version: 2, tratamientos: [], cambios: [] };
}

export function nuevoId(): string {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) {
    return crypto.randomUUID();
  }
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 10)}`;
}

/* ------------------------------------------------------------------ */
/* Reglas                                                              */
/* ------------------------------------------------------------------ */

export function tratamientoActivo(tratamiento: Tratamiento, referencia = hoy()): boolean {
  return !tratamiento.fin || tratamiento.fin >= referencia;
}

/** Texto corto: "50 mg · cada 7 días". Omite lo que no se completó. */
export function resumenTratamiento(tratamiento: Tratamiento): string {
  return [tratamiento.dosis, tratamiento.frecuencia]
    .map((parte) => parte.trim())
    .filter(Boolean)
    .join(" · ");
}

export function validarTratamiento(entrada: EntradaTratamiento): string | null {
  if (!entrada.nombre.trim()) return "Escribí el nombre del medicamento.";
  if (!entrada.inicio) return "Elegí la fecha de inicio.";
  if (entrada.fin && entrada.fin < entrada.inicio) {
    return "La fecha de fin no puede ser anterior al inicio.";
  }
  return null;
}

export function validarCambio(entrada: EntradaCambio): string | null {
  if (!entrada.fecha) return "Elegí la fecha del cambio.";
  if (!entrada.descripcion.trim()) return "Contá qué cambió o cómo te sentís.";
  return null;
}

function limpiar(valor: string | null): string | null {
  const texto = (valor ?? "").trim();
  return texto ? texto : null;
}

export function crearTratamiento(entrada: EntradaTratamiento): Tratamiento {
  return {
    id: nuevoId(),
    nombre: entrada.nombre.trim(),
    dosis: entrada.dosis.trim(),
    frecuencia: entrada.frecuencia.trim(),
    inicio: entrada.inicio,
    fin: entrada.fin || null,
    profesional: limpiar(entrada.profesional),
  };
}

export function crearCambio(entrada: EntradaCambio): Cambio {
  return {
    id: nuevoId(),
    fecha: entrada.fecha,
    descripcion: entrada.descripcion.trim(),
    foto: entrada.foto || null,
  };
}

/** Reemplaza un elemento por id, o lo agrega si no existe. */
export function guardarEnLista<T extends { id: string }>(lista: T[], elemento: T): T[] {
  const existe = lista.some((item) => item.id === elemento.id);
  return existe ? lista.map((item) => (item.id === elemento.id ? elemento : item)) : [...lista, elemento];
}

/* ------------------------------------------------------------------ */
/* Línea de tiempo                                                     */
/* ------------------------------------------------------------------ */

export function lineaDeTiempo(datos: Datos, filtro: Filtro = "todo"): Evento[] {
  const eventos: Evento[] = [];

  if (filtro !== "cambios") {
    for (const tratamiento of datos.tratamientos) {
      eventos.push({ tipo: "tratamiento", fecha: tratamiento.inicio, tratamiento });
    }
  }
  if (filtro !== "tratamientos") {
    for (const cambio of datos.cambios) {
      eventos.push({ tipo: "cambio", fecha: cambio.fecha, cambio });
    }
  }

  return eventos.sort((a, b) => {
    if (a.fecha !== b.fecha) return a.fecha < b.fecha ? 1 : -1;
    return a.tipo === "cambio" ? -1 : 1;
  });
}

export interface GrupoMes {
  mes: string;
  eventos: Evento[];
}

/** Agrupa una lista ya ordenada, sin depender de fechas de otros meses. */
export function agruparPorMes(eventos: Evento[]): GrupoMes[] {
  const grupos: GrupoMes[] = [];
  for (const evento of eventos) {
    const mes = evento.fecha.slice(0, 7);
    const ultimo = grupos.at(-1);
    if (ultimo?.mes === mes) {
      ultimo.eventos.push(evento);
    } else {
      grupos.push({ mes, eventos: [evento] });
    }
  }
  return grupos;
}

export function tratamientosEnCurso(datos: Datos, referencia = hoy()): Tratamiento[] {
  return datos.tratamientos
    .filter((tratamiento) => tratamientoActivo(tratamiento, referencia))
    .sort((a, b) => (a.inicio < b.inicio ? 1 : -1));
}

/* ------------------------------------------------------------------ */
/* Datos de ejemplo                                                    */
/* ------------------------------------------------------------------ */

/** Datos ficticios, relativos a hoy, para probar la app sin cargar nada. */
export function datosDemo(referencia = hoy()): Datos {
  const hace = (meses: number) => restarMeses(referencia, meses);

  return {
    version: 2,
    tratamientos: [
      {
        id: nuevoId(),
        nombre: "Testosterona",
        dosis: "50 mg",
        frecuencia: "cada 7 días",
        inicio: hace(8),
        fin: null,
        profesional: "Dra. Paz Ruiz · Endocrinología",
      },
      {
        id: nuevoId(),
        nombre: "Espironolactona",
        dosis: "50 mg",
        frecuencia: "cada 12 horas",
        inicio: hace(11),
        fin: null,
        profesional: "Dra. Paz Ruiz · Endocrinología",
      },
      {
        id: nuevoId(),
        nombre: "Estradiol",
        dosis: "1 mg",
        frecuencia: "cada 24 horas",
        inicio: hace(11),
        fin: sumarDias(hace(11), 90),
        profesional: null,
      },
    ],
    cambios: [
      {
        id: nuevoId(),
        fecha: hace(1),
        descripcion:
          "La voz se está asentando. Me costó un toque el cambio, pero escucharme en audios ya me hace sentir más yo.",
        foto: null,
      },
      {
        id: nuevoId(),
        fecha: hace(3),
        descripcion:
          "Primera ronda de análisis con la endocrinóloga. Todo en rango, seguimos con la misma dosis.",
        foto: null,
      },
      {
        id: nuevoId(),
        fecha: hace(5),
        descripcion:
          "Fui a comprar ropa sola por primera vez. Probarme cosas frente al espejo dejó de ser una pelea.",
        foto: null,
      },
      {
        id: nuevoId(),
        fecha: hace(9),
        descripcion:
          "Arranqué el tratamiento. Mucha emoción y un poco de miedo, pero después de años de espera por fin estaba ahí.",
        foto: null,
      },
    ],
  };
}
