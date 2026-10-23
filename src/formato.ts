/** Fechas de calendario en `AAAA-MM-DD`, sin zonas horarias ni corrimientos. */

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

const MESES_CORTOS = [
  "ene",
  "feb",
  "mar",
  "abr",
  "may",
  "jun",
  "jul",
  "ago",
  "sep",
  "oct",
  "nov",
  "dic",
];

const dos = (n: number) => String(n).padStart(2, "0");

export function aFecha(iso: string): Date {
  const [anio, mes, dia] = iso.slice(0, 10).split("-").map(Number);
  return new Date(anio ?? 1970, (mes ?? 1) - 1, dia ?? 1);
}

export function aISO(fecha: Date): string {
  return `${fecha.getFullYear()}-${dos(fecha.getMonth() + 1)}-${dos(fecha.getDate())}`;
}

export function hoy(): string {
  return aISO(new Date());
}

export function sumarDias(iso: string, dias: number): string {
  const fecha = aFecha(iso);
  fecha.setDate(fecha.getDate() + dias);
  return aISO(fecha);
}

export function restarMeses(iso: string, meses: number): string {
  const fecha = aFecha(iso);
  const dia = fecha.getDate();
  fecha.setDate(1);
  fecha.setMonth(fecha.getMonth() - meses);
  const ultimoDia = new Date(fecha.getFullYear(), fecha.getMonth() + 1, 0).getDate();
  fecha.setDate(Math.min(dia, ultimoDia));
  return aISO(fecha);
}

/** "12 de octubre de 2026" */
export function fechaLarga(iso: string): string {
  const fecha = aFecha(iso);
  return `${fecha.getDate()} de ${MESES[fecha.getMonth()]} de ${fecha.getFullYear()}`;
}

/** "12 oct 2026" */
export function fechaCorta(iso: string): string {
  const fecha = aFecha(iso);
  return `${fecha.getDate()} ${MESES_CORTOS[fecha.getMonth()]} ${fecha.getFullYear()}`;
}

/** "octubre 2026" */
export function mesTexto(iso: string): string {
  const fecha = aFecha(iso);
  return `${MESES[fecha.getMonth()]} ${fecha.getFullYear()}`;
}

/** "desde el 12 de octubre de 2026" / "12 oct 2026 — 3 mar 2027" */
export function rangoTexto(inicio: string, fin: string | null): string {
  return fin ? `${fechaCorta(inicio)} — ${fechaCorta(fin)}` : `Desde el ${fechaLarga(inicio)}`;
}

/** Días completos transcurridos desde una fecha. */
export function diasDesde(iso: string, hasta = hoy()): number {
  const ms = aFecha(hasta).getTime() - aFecha(iso).getTime();
  return Math.max(0, Math.round(ms / 86_400_000));
}

/** "hace 3 meses" aproximado, para la cabecera de un tratamiento en curso. */
export function duracionTexto(iso: string, hasta = hoy()): string {
  const dias = diasDesde(iso, hasta);
  if (dias === 0) return "empieza hoy";
  if (dias < 31) return `hace ${dias} ${dias === 1 ? "día" : "días"}`;
  const meses = Math.round(dias / 30.44);
  if (meses < 24) return `hace ${meses} ${meses === 1 ? "mes" : "meses"}`;
  const anios = Math.floor(meses / 12);
  return `hace ${anios} ${anios === 1 ? "año" : "años"}`;
}
