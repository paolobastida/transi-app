/** Reduce una foto antes de guardarla: el navegador tiene poco espacio local. */

const LADO_MAXIMO = 1200;
const CALIDAD = 0.78;

function cargarImagen(url: string): Promise<HTMLImageElement> {
  return new Promise((resolver, rechazar) => {
    const imagen = new Image();
    imagen.onload = () => resolver(imagen);
    imagen.onerror = () => rechazar(new Error("No pudimos leer esa imagen. Probá con una foto JPG o PNG."));
    imagen.src = url;
  });
}

/** Acepta un File elegido desde disco o un Blob capturado por la cámara:
 *  un solo camino de compresión para las dos formas de conseguir una foto. */
export async function comprimirImagen(imagen: Blob): Promise<string> {
  const url = URL.createObjectURL(imagen);
  try {
    const imagen = await cargarImagen(url);
    const escala = Math.min(1, LADO_MAXIMO / Math.max(imagen.width, imagen.height));
    const ancho = Math.max(1, Math.round(imagen.width * escala));
    const alto = Math.max(1, Math.round(imagen.height * escala));

    const lienzo = document.createElement("canvas");
    lienzo.width = ancho;
    lienzo.height = alto;
    const contexto = lienzo.getContext("2d");
    if (!contexto) throw new Error("Tu navegador no pudo procesar la imagen.");

    contexto.drawImage(imagen, 0, 0, ancho, alto);
    return lienzo.toDataURL("image/jpeg", CALIDAD);
  } finally {
    URL.revokeObjectURL(url);
  }
}
