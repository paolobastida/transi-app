/** Utilidades de fecha de la interfaz. */

const MESES = [
  "enero",
  "febrero",
  "marzo",
  "abril",
  "mayo",
  "junio",
  "julio",
  "agosto",
  "septiembre",
  "octubre",
  "noviembre",
  "diciembre",
];

const dos = (n: number) => String(n).padStart(2, "0");

/** Fecha de calendario `AAAA-MM-DD` (ya viene así del backend). */
export function fechaTexto(iso: string): string {
  return iso.slice(0, 10);
}

/** Fecha y hora local `AAAA-MM-DD HH:mm`. */
export function fechaHoraTexto(iso: string): string {
  const fecha = new Date(iso);
  if (Number.isNaN(fecha.getTime())) return iso;
  return `${fecha.getFullYear()}-${dos(fecha.getMonth() + 1)}-${dos(fecha.getDate())} ${dos(fecha.getHours())}:${dos(fecha.getMinutes())}`;
}

/** Minutos desde medianoche como `HH:mm`. */
export function horaTexto(minutos: number): string {
  return `${dos(Math.floor(minutos / 60))}:${dos(minutos % 60)}`;
}

/** La fecha de hoy en hora local, como `AAAA-MM-DD`. */
export function hoy(): string {
  const fecha = new Date();
  return `${fecha.getFullYear()}-${dos(fecha.getMonth() + 1)}-${dos(fecha.getDate())}`;
}

/** Cualquier `Date` local como `AAAA-MM-DD` (para `<input type="date">`). */
export function aFechaInput(fecha: Date): string {
  return `${fecha.getFullYear()}-${dos(fecha.getMonth() + 1)}-${dos(fecha.getDate())}`;
}

/** `AAAA-MM-DD` a un `Date` local (sin el corrimiento de UTC). */
export function aFecha(iso: string): Date {
  const [anio, mes, dia] = iso.slice(0, 10).split("-").map(Number);
  return new Date(anio, (mes ?? 1) - 1, dia ?? 1);
}

/** Encabezado de mes para la línea de tiempo. */
export function mesTexto(iso: string): string {
  const [anio, mes] = iso.slice(0, 10).split("-");
  return `${MESES[Number(mes) - 1] ?? ""} ${anio}`;
}

/** Resta meses a una fecha local. */
export function restarMeses(fecha: Date, meses: number): Date {
  const copia = new Date(fecha);
  copia.setMonth(copia.getMonth() - meses);
  return copia;
}
