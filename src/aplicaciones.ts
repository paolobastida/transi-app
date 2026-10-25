/**
 * Aplicaciones en el tiempo.
 *
 * La frecuencia de cada medicamento es texto que escribió la persona
 * ("cada 7 días", "cada 12 horas"). Acá se interpreta para saber en qué fechas
 * se toma cada medicamento, y con eso se arma el calendario de aplicaciones.
 *
 * La interpretación es prudente: si el texto no se entiende, no se falla. Se
 * asume una aplicación por día —que es exactamente el comportamiento previo de
 * la app— y `frecuenciaInterpretable` permite avisar en pantalla que la
 * frecuencia quedó sin interpretar.
 */

import { aFecha, diasDesde, sumarDias } from "./formato";
import type { Datos, Medicamento, Tratamiento } from "./modelo";

/** Cadencia entre aplicaciones. `dias` cubre también las frecuencias en horas. */
export type Cadencia =
  | { tipo: "dias"; cada: number }
  | { tipo: "meses"; cada: number };

export const CADENCIA_DIARIA: Cadencia = { tipo: "dias", cada: 1 };

/** Días hacia adelante que se agendan en el sistema operativo. */
export const HORIZONTE_DIAS = 90;

/* ------------------------------------------------------------------ */
/* Interpretación de la frecuencia                                     */
/* ------------------------------------------------------------------ */

const ACENTOS = /[\u0300-\u036f]/g;

function normalizar(texto: string): string {
  return texto
    .toLowerCase()
    .normalize("NFD")
    .replace(ACENTOS, "")
    // "cada 14 días (IM)": el paréntesis agrega contexto, no frecuencia.
    .replace(/\([^)]*\)/g, " ")
    .replace(/[.,;:]+$/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

const NUMEROS: Record<string, number> = {
  un: 1,
  una: 1,
  uno: 1,
  dos: 2,
  tres: 3,
  cuatro: 4,
  cinco: 5,
  seis: 6,
  siete: 7,
  ocho: 8,
  nueve: 9,
  diez: 10,
  once: 11,
  doce: 12,
};

function aNumero(texto: string): number | null {
  if (/^\d+$/.test(texto)) return Number(texto);
  return NUMEROS[texto] ?? null;
}

/** Frecuencias dichas con palabras, que no encajan en el patrón "cada N …". */
const FRECUENCIAS_FIJAS: Record<string, Cadencia> = {
  "todos los dias": CADENCIA_DIARIA,
  "cada dia": CADENCIA_DIARIA,
  diario: CADENCIA_DIARIA,
  diaria: CADENCIA_DIARIA,
  "a diario": CADENCIA_DIARIA,
  "al dia": CADENCIA_DIARIA,
  "una vez al dia": CADENCIA_DIARIA,
  "1 vez al dia": CADENCIA_DIARIA,
  semanal: { tipo: "dias", cada: 7 },
  semanalmente: { tipo: "dias", cada: 7 },
  "cada semana": { tipo: "dias", cada: 7 },
  "una vez por semana": { tipo: "dias", cada: 7 },
  "una vez a la semana": { tipo: "dias", cada: 7 },
  quincenal: { tipo: "dias", cada: 15 },
  mensual: { tipo: "meses", cada: 1 },
  mensualmente: { tipo: "meses", cada: 1 },
  "cada mes": { tipo: "meses", cada: 1 },
  "al mes": { tipo: "meses", cada: 1 },
  "una vez al mes": { tipo: "meses", cada: 1 },
};

/**
 * "cada 7 días" / "cada dos semanas" / "cada 6 horas".
 *
 * Sin anclas a propósito: quien carga el tratamiento suele escribir la
 * presentación o la vía junto con la frecuencia ("cada 14 días · intramuscular",
 * "250 mg / 5 ml · cada 14 días"). Si el patrón tuviera que ocupar toda la
 * frase, esas frecuencias caerían al caso diario por default.
 */
const PATRON_CADA =
  /cada (\d+|un|una|uno|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez|once|doce) (minuto|hora|dia|semana|mes)(es|s)?\b/;

function porUnidad(cantidad: number, unidad: string): Cadencia | null {
  if (!Number.isFinite(cantidad) || cantidad <= 0) return null;

  switch (unidad) {
    case "minuto":
      // Menos de un día siempre significa "todos los días": los minutos
      // concretos ya viven en los horarios del medicamento.
      if (cantidad < 1440) return CADENCIA_DIARIA;
      return cantidad % 1440 === 0 ? { tipo: "dias", cada: cantidad / 1440 } : null;
    case "hora":
      if (cantidad <= 24) return CADENCIA_DIARIA;
      return cantidad % 24 === 0 ? { tipo: "dias", cada: cantidad / 24 } : null;
    case "dia":
      return { tipo: "dias", cada: cantidad };
    case "semana":
      return { tipo: "dias", cada: cantidad * 7 };
    case "mes":
      return { tipo: "meses", cada: cantidad };
    default:
      return null;
  }
}

/**
 * Interpreta el texto de frecuencia. Devuelve `null` cuando no se entiende:
 * el llamador decide si avisar o asumir el comportamiento diario anterior.
 */
export function parsearFrecuencia(texto: string): Cadencia | null {
  const frase = normalizar(texto);
  if (!frase) return null;

  const fija = FRECUENCIAS_FIJAS[frase];
  if (fija) return fija;

  const cada = PATRON_CADA.exec(frase);
  if (!cada) return null;

  const cantidad = aNumero(cada[1] as string);
  if (cantidad === null) return null;
  return porUnidad(cantidad, cada[2] as string);
}

/** Cadencia efectiva de un medicamento: sin texto entendible, se asume diaria. */
export function cadenciaDe(medicamento: Medicamento): Cadencia {
  return parsearFrecuencia(medicamento.frecuencia) ?? CADENCIA_DIARIA;
}

/**
 * `false` solo si la persona escribió una frecuencia que no supimos leer.
 * Un campo vacío no es un problema: no impone restricción, se asume diaria.
 */
export function frecuenciaInterpretable(medicamento: Medicamento): boolean {
  const texto = medicamento.frecuencia.trim();
  return texto === "" || parsearFrecuencia(texto) !== null;
}

/* ------------------------------------------------------------------ */
/* Calendario                                                          */
/* ------------------------------------------------------------------ */

/**
 * `true` si `fecha` cae en el día de aplicación de un tratamiento iniciado
 * en `inicio`. El ancla es siempre la fecha de inicio del tratamiento.
 */
export function esDiaDeAplicacion(inicio: string, fecha: string, cadencia: Cadencia): boolean {
  if (fecha < inicio) return false;

  if (cadencia.tipo === "dias") {
    return diasDesde(inicio, fecha) % cadencia.cada === 0;
  }

  // Meses: ancla en el día del inicio, tolerando los meses más cortos
  // (empezar el 31 cae el 28 en febrero, no desaparece ese mes).
  const origen = aFecha(inicio);
  const dia = aFecha(fecha);
  const transcurridos = (dia.getFullYear() - origen.getFullYear()) * 12 + (dia.getMonth() - origen.getMonth());
  if (transcurridos < 0 || transcurridos % cadencia.cada !== 0) return false;

  const ultimoDelMes = new Date(dia.getFullYear(), dia.getMonth() + 1, 0).getDate();
  return dia.getDate() === Math.min(origen.getDate(), ultimoDelMes);
}

/** Días de aplicación entre `desde` y `hasta`, ambos incluidos. */
export function diasDeAplicacion(
  inicio: string,
  cadencia: Cadencia,
  desde: string,
  hasta: string,
): string[] {
  const dias: string[] = [];
  if (hasta < desde) return dias;

  let dia = desde > inicio ? desde : inicio;
  // Red de seguridad: nunca recorrer más de ~11 años de un tirón.
  for (let pasos = 0; dia <= hasta && pasos <= 4000; pasos++) {
    if (esDiaDeAplicacion(inicio, dia, cadencia)) dias.push(dia);
    dia = sumarDias(dia, 1);
  }
  return dias;
}

export interface Aplicacion {
  /** `AAAA-MM-DD|medicamentoId|HH:MM`: la misma clave que usan los avisos. */
  clave: string;
  fecha: string;
  /** Hora "HH:MM", o `null` si el medicamento no tiene horario cargado. */
  horario: string | null;
  medicamento: Medicamento;
  tratamiento: Tratamiento;
}

function comparar(a: Aplicacion, b: Aplicacion): number {
  if (a.fecha !== b.fecha) return a.fecha < b.fecha ? -1 : 1;
  // Sin hora al final del día: no sabemos dónde va.
  const horaA = a.horario ?? "99:99";
  const horaB = b.horario ?? "99:99";
  if (horaA !== horaB) return horaA < horaB ? -1 : 1;
  return a.medicamento.nombre.localeCompare(b.medicamento.nombre);
}

/** Aplicaciones de un tratamiento dentro del rango, ordenadas. */
export function aplicacionesDe(tratamiento: Tratamiento, desde: string, hasta: string): Aplicacion[] {
  const lista: Aplicacion[] = [];
  if (hasta < desde) return lista;

  const inicio = tratamiento.inicio;
  const desdeTratamiento = desde > inicio ? desde : inicio;

  for (const medicamento of tratamiento.medicamentos) {
    const hastaMedicamento =
      tratamiento.fin && tratamiento.fin < hasta ? tratamiento.fin : hasta;
    if (hastaMedicamento < desdeTratamiento) continue;

    for (const fecha of diasDeAplicacion(inicio, cadenciaDe(medicamento), desdeTratamiento, hastaMedicamento)) {
      // Sin horario cargado la aplicación existe, pero no tiene hora.
      const horarios: (string | null)[] = medicamento.horarios.length > 0 ? medicamento.horarios : [null];
      for (const horario of horarios) {
        lista.push({
          clave: `${fecha}|${medicamento.id}|${horario ?? "sin-hora"}`,
          fecha,
          horario,
          medicamento,
          tratamiento,
        });
      }
    }
  }

  return lista.sort(comparar);
}

/** Aplicaciones de todos los tratamientos dentro del rango, ordenadas. */
export function aplicaciones(datos: Datos, desde: string, hasta: string): Aplicacion[] {
  return datos.tratamientos
    .flatMap((tratamiento) => aplicacionesDe(tratamiento, desde, hasta))
    .sort(comparar);
}

/** Aplicaciones de hoy. */
export function aplicacionesHoy(datos: Datos, fecha: string): Aplicacion[] {
  return aplicaciones(datos, fecha, fecha);
}

/** De mañana hasta `fecha + dias`. */
export function aplicacionesProximas(datos: Datos, fecha: string, dias = 14): Aplicacion[] {
  return aplicaciones(datos, sumarDias(fecha, 1), sumarDias(fecha, dias));
}

/** De hace `dias` hasta ayer. */
export function aplicacionesRecientes(datos: Datos, fecha: string, dias = 7): Aplicacion[] {
  return aplicaciones(datos, sumarDias(fecha, -dias), sumarDias(fecha, -1));
}

export interface GrupoDia {
  fecha: string;
  aplicaciones: Aplicacion[];
}

/** Agrupa una lista ya ordenada por día calendario. */
export function agruparPorDia(lista: Aplicacion[]): GrupoDia[] {
  const grupos: GrupoDia[] = [];
  for (const aplicacion of lista) {
    const ultimo = grupos.at(-1);
    if (ultimo?.fecha === aplicacion.fecha) {
      ultimo.aplicaciones.push(aplicacion);
    } else {
      grupos.push({ fecha: aplicacion.fecha, aplicaciones: [aplicacion] });
    }
  }
  return grupos;
}

/**
 * Fechas concretas de un medicamento hacia adelante, para agendar en el
 * sistema operativo. Un arreglo vacío significa "sin tomas pendientes"; el
 * llamador debe distinguirlo de una cadencia diaria, que no necesita fechas.
 */
export function fechasDeMedicamento(
  tratamiento: Tratamiento,
  medicamento: Medicamento,
  desde: string,
  hasta: string,
): string[] {
  const cadencia = cadenciaDe(medicamento);
  const inicio = tratamiento.inicio;
  const desdeMedicamento = desde > inicio ? desde : inicio;
  const hastaMedicamento = tratamiento.fin && tratamiento.fin < hasta ? tratamiento.fin : hasta;
  if (hastaMedicamento < desdeMedicamento) return [];
  return diasDeAplicacion(inicio, cadencia, desdeMedicamento, hastaMedicamento);
}
