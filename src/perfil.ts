/** Identidad de la persona: un perfil local, opcionalmente asociado a un proveedor. */

export type Proveedor = "google" | "apple" | "facebook";

export const PROVEEDORES: Proveedor[] = ["google", "apple", "facebook"];

export interface Perfil {
  proveedor: Proveedor;
  sub: string;
  nombre: string;
  email: string;
}

export function esProveedor(valor: unknown): valor is Proveedor {
  return valor === "google" || valor === "apple" || valor === "facebook";
}

/** Clave estable para separar los datos de cada cuenta en este dispositivo. */
export function clavePerfil(perfil: Perfil): string {
  return `${perfil.proveedor}:${perfil.sub}`;
}

export function nombreVisible(perfil: Perfil): string {
  return perfil.nombre.trim() || perfil.email;
}

export function iniciales(perfil: Perfil): string {
  const partes = nombreVisible(perfil)
    .split(/\s+/)
    .map((parte) => parte.trim())
    .filter(Boolean);
  const primera = partes[0]?.[0] ?? "?";
  const ultima = partes.length > 1 ? (partes[partes.length - 1]?.[0] ?? "") : "";
  return `${primera}${ultima}`.toUpperCase();
}

export function etiquetaProveedor(proveedor: Proveedor): string {
  return { google: "Google", apple: "Apple", facebook: "Facebook" }[proveedor];
}
