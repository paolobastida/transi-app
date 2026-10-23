/** Conversión entre archivos del webview y base64 (lo que viaja a Rust). */

const TROZO = 0x8000;

export function bytesABase64(bytes: Uint8Array): string {
  let binario = "";
  for (let i = 0; i < bytes.length; i += TROZO) {
    binario += String.fromCharCode(...bytes.subarray(i, i + TROZO));
  }
  return btoa(binario);
}

export async function archivoABase64(archivo: File): Promise<string> {
  return bytesABase64(new Uint8Array(await archivo.arrayBuffer()));
}

export function base64ABlob(base64: string, tipo: string): Blob {
  const binario = atob(base64);
  const bytes = new Uint8Array(binario.length);
  for (let i = 0; i < binario.length; i += 1) {
    bytes[i] = binario.charCodeAt(i);
  }
  return new Blob([bytes], { type: tipo });
}

export function mimeDeFoto(nombre: string): string {
  const limpio = nombre.toLowerCase();
  if (limpio.endsWith(".png")) return "image/png";
  if (limpio.endsWith(".webp")) return "image/webp";
  if (limpio.endsWith(".gif")) return "image/gif";
  return "image/jpeg";
}

export function mimeDeAudio(nombre: string): string {
  const limpio = nombre.toLowerCase();
  if (limpio.endsWith(".m4a") || limpio.endsWith(".mp4")) return "audio/mp4";
  if (limpio.endsWith(".mp3")) return "audio/mpeg";
  if (limpio.endsWith(".ogg")) return "audio/ogg";
  return "audio/webm";
}
