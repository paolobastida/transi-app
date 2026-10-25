/** Sesión local: identifica un perfil sin backend y separa los datos por cuenta. */

import { cargar, configurarPerfil, datosAnonimos, guardar, tieneDatos } from "./almacen";
import type { Datos } from "./modelo";
import { clavePerfil, esProveedor, type Perfil } from "./perfil";

export type { Perfil };

const CLAVE_SESION = "transi.sesion";

let cache: Perfil | null | undefined;

function normalizarPerfil(valor: unknown): Perfil | null {
  if (!valor || typeof valor !== "object") return null;
  const bruto = valor as Record<string, unknown>;
  const sub = typeof bruto["sub"] === "string" ? bruto["sub"].trim() : "";
  const email = typeof bruto["email"] === "string" ? bruto["email"].trim() : "";
  const proveedor = esProveedor(bruto["proveedor"]) ? bruto["proveedor"] : "google";
  if (!sub || !email) return null;
  const nombre =
    (typeof bruto["nombre"] === "string" && bruto["nombre"].trim()) || email;
  return { proveedor, sub, nombre, email };
}

export function leerPerfil(): Perfil | null {
  if (cache !== undefined) return cache;
  try {
    cache = normalizarPerfil(JSON.parse(localStorage.getItem(CLAVE_SESION) ?? "null"));
  } catch {
    cache = null;
  }
  return cache;
}

export function perfilActual(): Perfil | null {
  return leerPerfil();
}

/** Activa la cuenta y avisa si conviene ofrecer los datos que ya había sin cuenta. */
export function entrarConPerfil(perfil: Perfil): { cuentaVacia: boolean; hayAnonimos: boolean } {
  try {
    localStorage.setItem(CLAVE_SESION, JSON.stringify(perfil));
  } catch {
    // Sin sesión persistente la cuenta dura hasta recargar; los datos siguen accesibles.
  }
  cache = perfil;
  configurarPerfil(clavePerfil(perfil));
  const cuenta = cargar();
  const anonimos = datosAnonimos();
  return { cuentaVacia: !tieneDatos(cuenta), hayAnonimos: tieneDatos(anonimos) };
}

export function salirDeCuenta(): void {
  try {
    localStorage.removeItem(CLAVE_SESION);
  } catch {
    // Nada que borrar.
  }
  cache = null;
  configurarPerfil(null);
}

/** Copia los datos del perfil anónimo al perfil activo. */
export function importarDatosAnonimos(): boolean {
  const anonimos: Datos = datosAnonimos();
  if (!tieneDatos(anonimos)) return false;
  return guardar(anonimos);
}
