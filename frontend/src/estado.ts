import type { Usuario } from "./tipos";

/// Sesión activa en memoria. Los tokens viven en Rust (llavero del sistema).
export const estado: { usuario: Usuario | null } = { usuario: null };
