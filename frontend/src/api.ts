import { invoke } from "@tauri-apps/api/core";
import type {
  Cambio,
  EntradaAdjunto,
  EntradaTratamiento,
  EventoTimeline,
  Tratamiento,
  Usuario,
} from "./tipos";

/// Todas las llamadas al backend Rust viven acá. El frontend nunca ve tokens:
/// la sesión y el refresco los maneja Rust en el llavero del sistema.
export const api = {
  registrar: (email: string, clave: string) =>
    invoke<void>("registrar", { email, clave }),

  entrar: (email: string, clave: string) =>
    invoke<Usuario>("entrar", { email, clave }),

  sesionActual: () => invoke<Usuario | null>("sesion_actual"),

  salir: () => invoke<void>("salir"),

  listarTratamientos: (usuarioId: string, estado?: string) =>
    invoke<Tratamiento[]>("listar_tratamientos", { usuarioId, estado }),

  crearTratamiento: (usuarioId: string, entrada: EntradaTratamiento) =>
    invoke<Tratamiento>("crear_tratamiento", { usuarioId, entrada }),

  actualizarTratamiento: (tratamiento: Tratamiento) =>
    invoke<void>("actualizar_tratamiento", { tratamiento }),

  desactivarTratamiento: (id: string, usuarioId: string) =>
    invoke<void>("desactivar_tratamiento", { id, usuarioId }),

  listarCambios: (usuarioId: string) =>
    invoke<Cambio[]>("listar_cambios", { usuarioId }),

  crearCambio: (
    usuarioId: string,
    fecha: string,
    descripcion: string,
    adjuntos: EntradaAdjunto[],
  ) => invoke<Cambio>("crear_cambio", { usuarioId, fecha, descripcion, adjuntos }),

  desactivarCambio: (id: string, usuarioId: string) =>
    invoke<void>("desactivar_cambio", { id, usuarioId }),

  lineaDeTiempo: (usuarioId: string, desde?: string, hasta?: string) =>
    invoke<EventoTimeline[]>("linea_de_tiempo", { usuarioId, desde, hasta }),

  pendientes: (usuarioId: string) =>
    invoke<number>("pendientes", { usuarioId }),

  ultimoRespaldo: () => invoke<string | null>("ultimo_respaldo"),

  respaldar: (usuarioId: string) => invoke<void>("respaldar", { usuarioId }),

  restaurar: (usuarioId: string) => invoke<void>("restaurar", { usuarioId }),

  solicitarPermisoNotificaciones: () =>
    invoke<boolean>("solicitar_permiso_notificaciones"),
};
