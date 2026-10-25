/** Persistencia local. La app no habla con ningún servidor. */

import { esFechaValida } from "./formato";
import type { Cambio, Datos, Medicamento, Tratamiento } from "./modelo";
import { datosVacios, normalizarHorarios, nuevoId } from "./modelo";

const CLAVE = "transi.datos";
const SUFIJO_ROTO = ".roto";
const VERSION = 4;

let memoria: Datos | null = null;
let claveDatos = CLAVE;

/** Cambia el espacio de datos: anónimo o la identidad `proveedor:sub` de una cuenta. */
export function configurarPerfil(identidad: string | null): void {
  claveDatos = identidad ? `${CLAVE}.${identidad}` : CLAVE;
  memoria = null;
}

/** Clave activa: la que esta pestaña lee y escribe. */
export function claveActiva(): string {
  return claveDatos;
}

/** Descarta la caché en memoria para que la próxima lectura vaya a localStorage. */
export function invalidarMemoria(): void {
  memoria = null;
}

function texto(valor: unknown): string {
  return typeof valor === "string" ? valor : "";
}

function textoONulo(valor: unknown): string | null {
  return typeof valor === "string" && valor.trim() ? valor : null;
}

function comoMedicamento(valor: unknown): Medicamento | null {
  if (!valor || typeof valor !== "object") return null;
  const bruto = valor as Record<string, unknown>;
  const nombre = texto(bruto["nombre"]).trim();
  if (!nombre) return null;
  const crudos = Array.isArray(bruto["horarios"]) ? (bruto["horarios"] as unknown[]) : [];
  return {
    id: texto(bruto["id"]) || nuevoId(),
    nombre,
    dosis: texto(bruto["dosis"]),
    frecuencia: texto(bruto["frecuencia"]),
    // Respaldos anteriores a los recordatorios no traen horarios: quedan vacíos.
    horarios: normalizarHorarios(crudos.filter((h): h is string => typeof h === "string")),
  };
}

function comoTratamiento(valor: unknown): Tratamiento | null {
  if (!valor || typeof valor !== "object") return null;
  const bruto = valor as Record<string, unknown>;
  const inicio = texto(bruto["inicio"]).slice(0, 10);
  if (!esFechaValida(inicio)) return null;

  const medicamentos = Array.isArray(bruto["medicamentos"])
    ? bruto["medicamentos"].map(comoMedicamento).filter((x): x is Medicamento => x !== null)
    : [];

  // Compatibilidad con la versión anterior: un tratamiento era un medicamento.
  if (medicamentos.length === 0) {
    const nombre = texto(bruto["nombre"]).trim();
    if (!nombre) return null;
    medicamentos.push({
      id: nuevoId(),
      nombre,
      dosis: texto(bruto["dosis"]),
      frecuencia: texto(bruto["frecuencia"]),
      horarios: [],
    });
  }

  const fin = texto(bruto["fin"]).slice(0, 10);
  return {
    id: texto(bruto["id"]) || nuevoId(),
    medicamentos,
    inicio,
    // Un `fin` ilegible se descarta: si no, el tratamiento queda "En curso" para siempre.
    fin: esFechaValida(fin) ? fin : null,
    profesional: textoONulo(bruto["profesional"]),
  };
}

function comoCambio(valor: unknown): Cambio | null {
  if (!valor || typeof valor !== "object") return null;
  const bruto = valor as Record<string, unknown>;
  const fecha = texto(bruto["fecha"]).slice(0, 10);
  const descripcion = texto(bruto["descripcion"]).trim();
  if (!descripcion || !esFechaValida(fecha)) return null;
  return {
    id: texto(bruto["id"]) || nuevoId(),
    fecha,
    descripcion,
    foto: textoONulo(bruto["foto"]),
    audio: textoONulo(bruto["audio"]),
  };
}

export interface OpcionesNormalizar {
  /**
   * Exige el sello `app: "transi"` y una versión conocida.
   * Solo para archivos importados: los datos de localStorage no lo traen.
   */
  respaldo?: boolean;
}

/** Acepta un objeto desconocido (de localStorage o de un archivo) y devuelve datos válidos. */
export function normalizar(valor: unknown, opciones: OpcionesNormalizar = {}): Datos | null {
  if (!valor || typeof valor !== "object") return null;
  const bruto = valor as Record<string, unknown>;

  if (opciones.respaldo) {
    if (bruto["app"] !== "transi") return null;
    const version = bruto["version"];
    if (typeof version === "number" && version > VERSION) return null;
  }

  if (!Array.isArray(bruto["tratamientos"]) || !Array.isArray(bruto["cambios"])) {
    return null;
  }
  return {
    version: VERSION,
    tratamientos: bruto["tratamientos"]
      .map(comoTratamiento)
      .filter((x): x is Tratamiento => x !== null),
    cambios: bruto["cambios"].map(comoCambio).filter((x): x is Cambio => x !== null),
  };
}

export function cargar(): Datos {
  if (memoria) return memoria;

  let bruto: string | null = null;
  try {
    bruto = localStorage.getItem(claveDatos);
  } catch {
    memoria = datosVacios();
    return memoria;
  }
  if (!bruto) {
    memoria = datosVacios();
    return memoria;
  }

  try {
    const normalizado = normalizar(JSON.parse(bruto));
    if (normalizado) {
      memoria = normalizado;
      return memoria;
    }
  } catch {
    // JSON ilegible: cae al resguardo de abajo.
  }

  // El respaldo no se pudo leer. Antes de que un guardado lo pise, guardamos
  // una copia aparte y dejamos la app en vacío avisando (ver main.ts).
  resguardarRoto(bruto);
  memoria = datosVacios();
  return memoria;
}

/** Copia aparte del respaldo ilegible, para que un guardado no lo destruya. */
function resguardarRoto(bruto: string): void {
  try {
    const clave = `${claveDatos}${SUFIJO_ROTO}`;
    if (localStorage.getItem(clave) !== null) return; // ya hay una copia previa
    localStorage.setItem(clave, bruto);
  } catch {
    // Sin espacio no hay nada que hacer: la app sigue en vacío.
  }
}

/** Texto crudo del respaldo ilegible, si existe. `null` si no hay. */
export function respaldoRoto(): string | null {
  try {
    return localStorage.getItem(`${claveDatos}${SUFIJO_ROTO}`);
  } catch {
    return null;
  }
}

/** Descarta la copia del respaldo ilegible. */
export function borrarRespaldoRoto(): boolean {
  try {
    localStorage.removeItem(`${claveDatos}${SUFIJO_ROTO}`);
    return true;
  } catch {
    return false;
  }
}

/** Guarda y actualiza la memoria. Devuelve false si el navegador no tiene espacio. */
export function guardar(datos: Datos): boolean {
  try {
    localStorage.setItem(claveDatos, JSON.stringify(datos));
    memoria = datos;
    return true;
  } catch {
    return false;
  }
}

/**
 * Aplica una mutación sobre los datos **frescos** de localStorage y guarda.
 *
 * Las vistas capturan los datos al montarse; si otra pestaña guardó en el
 * medio, escribir sobre esa copia vieja borraría lo que ella acaba de registrar.
 * Releer antes de mutar evita exactamente eso.
 */
export function actualizar(mutador: (datos: Datos) => Datos): boolean {
  memoria = null;
  return guardar(mutador(cargar()));
}

export function borrarTodo(): boolean {
  try {
    localStorage.removeItem(claveDatos);
    localStorage.removeItem(`${claveDatos}${SUFIJO_ROTO}`);
    memoria = datosVacios();
    return true;
  } catch {
    return false;
  }
}

/** Datos del perfil anónimo, sin importar qué cuenta esté activa. */
export function datosAnonimos(): Datos {
  try {
    const guardado = localStorage.getItem(CLAVE);
    return guardado ? (normalizar(JSON.parse(guardado)) ?? datosVacios()) : datosVacios();
  } catch {
    return datosVacios();
  }
}

export function tieneDatos(datos: Datos): boolean {
  return datos.tratamientos.length > 0 || datos.cambios.length > 0;
}

export function serializar(datos: Datos): string {
  return JSON.stringify({ app: "transi", ...datos }, null, 2);
}
