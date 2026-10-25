/** Decodificación de JWT sin verificar la firma: la validación real la hace el proveedor. */

function decodificarBase64Url(parte: string): string {
  const base64 = parte.replace(/-/g, "+").replace(/_/g, "/");
  const relleno = base64.padEnd(Math.ceil(base64.length / 4) * 4, "=");
  const binario = atob(relleno);
  const bytes = Uint8Array.from(binario, (caracter) => caracter.charCodeAt(0));
  return new TextDecoder().decode(bytes);
}

export function decodificarJwt(token: string): Record<string, unknown> {
  const partes = token.split(".");
  if (partes.length < 2 || !partes[1]) {
    throw new Error("La credencial no tiene el formato esperado.");
  }
  try {
    const payload: unknown = JSON.parse(decodificarBase64Url(partes[1]));
    if (!payload || typeof payload !== "object") throw new Error("payload");
    return payload as Record<string, unknown>;
  } catch {
    throw new Error("No pudimos leer la respuesta del proveedor.");
  }
}
