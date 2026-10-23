export interface Usuario {
  id: string;
  email: string;
}

export interface Tratamiento {
  id: string;
  usuarioId: string;
  nombre: string;
  dosis: string;
  frecuencia: string;
  fechaInicio: string;
  fechaFin: string | null;
  activo: boolean;
  via: string | null;
  presentacion: string | null;
  dosisCantidad: number | null;
  dosisUnidad: string | null;
  indicacion: string | null;
  profesionalNombre: string | null;
  profesionalEspecialidad: string | null;
  recordatorioMinutos: number[];
}

export interface EntradaTratamiento {
  nombre: string;
  dosis: string;
  frecuencia: string;
  fechaInicio: string;
  fechaFin: string | null;
  via: string | null;
  presentacion: string | null;
  dosisCantidad: number | null;
  dosisUnidad: string | null;
  indicacion: string | null;
  profesionalNombre: string | null;
  profesionalEspecialidad: string | null;
  recordatorioMinutos: number[];
}

export interface EntradaAdjunto {
  tipo: string;
  nombre: string;
  /** Contenido en base64. */
  contenido: string;
}

export interface Adjunto {
  id: string;
  cambioId: string;
  tipo: string;
  nombre: string;
  contenido: string;
}

export interface Cambio {
  id: string;
  usuarioId: string;
  fecha: string;
  descripcion: string;
  activo: boolean;
  adjuntos: Adjunto[];
}

export interface EventoTimeline {
  tipo: "tratamiento" | "cambio";
  fecha: string;
  titulo: string;
  detalle: string;
  referenciaId: string;
}
