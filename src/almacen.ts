/** Persistencia local. La app no habla con ningún servidor. */

import type { Cambio, Datos, Medicamento, Tratamiento } from "./modelo";
import { datosVacios, nuevoId } from "./modelo";

const CLAVE = "transi.datos";
const VERSION = 4;

let memoria: Datos | null = null;

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
  return {
    id: texto(bruto["id"]) || nuevoId(),
    nombre,
    dosis: texto(bruto["dosis"]),
    frecuencia: texto(bruto["frecuencia"]),
  };
}

function comoTratamiento(valor: unknown): Tratamiento | null {
  if (!valor || typeof valor !== "object") return null;
  const bruto = valor as Record<string, unknown>;
  const inicio = texto(bruto["inicio"]).slice(0, 10);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(inicio)) return null;

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
    });
  }

  return {
    id: texto(bruto["id"]) || nuevoId(),
    medicamentos,
    inicio,
    fin: textoONulo(bruto["fin"]),
    profesional: textoONulo(bruto["profesional"]),
  };
}

function comoCambio(valor: unknown): Cambio | null {
  if (!valor || typeof valor !== "object") return null;
  const bruto = valor as Record<string, unknown>;
  const fecha = texto(bruto["fecha"]).slice(0, 10);
  const descripcion = texto(bruto["descripcion"]).trim();
  if (!descripcion || !/^\d{4}-\d{2}-\d{2}$/.test(fecha)) return null;
  return {
    id: texto(bruto["id"]) || nuevoId(),
    fecha,
    descripcion,
    foto: textoONulo(bruto["foto"]),
    audio: textoONulo(bruto["audio"]),
  };
}

/** Acepta un objeto desconocido (de localStorage o de un archivo) y devuelve datos válidos. */
export function normalizar(valor: unknown): Datos | null {
  if (!valor || typeof valor !== "object") return null;
  const bruto = valor as Record<string, unknown>;
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
  try {
    const guardado = localStorage.getItem(CLAVE);
    memoria = guardado ? (normalizar(JSON.parse(guardado)) ?? datosVacios()) : datosVacios();
  } catch {
    memoria = datosVacios();
  }
  return memoria;
}

/** Guarda y actualiza la memoria. Devuelve false si el navegador no tiene espacio. */
export function guardar(datos: Datos): boolean {
  try {
    localStorage.setItem(CLAVE, JSON.stringify(datos));
    memoria = datos;
    return true;
  } catch {
    return false;
  }
}

export function borrarTodo(): boolean {
  try {
    localStorage.removeItem(CLAVE);
    memoria = datosVacios();
    return true;
  } catch {
    return false;
  }
}

export function serializar(datos: Datos): string {
  return JSON.stringify({ app: "transi", ...datos }, null, 2);
}
