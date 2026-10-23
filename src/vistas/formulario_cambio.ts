import { cargar, guardar } from "../almacen";
import { hoy } from "../formato";
import { comprimirImagen } from "../imagen";
import {
  crearCambio,
  guardarEnLista,
  validarCambio,
  type Cambio,
  type EntradaCambio,
} from "../modelo";
import { navegar } from "../rutas";
import { aviso, h } from "../ui";
import { barraGuardar, cabeceraFormulario, campo } from "./comunes";

export function vistaFormularioCambio(id?: string): HTMLElement {
  const datos = cargar();
  const existente = id ? datos.cambios.find((cambio) => cambio.id === id) : undefined;

  if (id && !existente) {
    navegar("/");
    return h("div");
  }

  const volver = (): void => (existente ? navegar(`/detalle/cambio/${existente.id}`) : navegar("/"));

  let foto: string | null = existente?.foto ?? null;

  const fecha = h("input", {
    type: "date",
    value: existente?.fecha ?? hoy(),
    required: true,
  });

  const descripcion = h("textarea", {
    rows: "5",
    placeholder: "¿Qué cambió? ¿Cómo te sentís?",
    required: true,
  });
  descripcion.value = existente?.descripcion ?? "";

  const vistaFoto = h("div", { class: "vista-foto" });
  const inputFoto = h("input", {
    type: "file",
    accept: "image/*",
    class: "oculto",
    onChange: (evento: Event) => {
      const archivo = (evento.target as HTMLInputElement).files?.[0];
      if (archivo) void elegirFoto(archivo);
    },
  });

  const botonFoto = h(
    "button",
    { class: "btn secundario", type: "button", onClick: () => inputFoto.click() },
    "Elegir foto",
  );

  const botonQuitar = h(
    "button",
    {
      class: "btn peligro chico oculto",
      type: "button",
      onClick: () => {
        foto = null;
        pintarFoto();
      },
    },
    "Quitar foto",
  );

  const pintarFoto = (): void => {
    vistaFoto.replaceChildren(foto ? h("img", { class: "foto-previa", src: foto, alt: "Foto elegida" }) : "");
    botonQuitar.classList.toggle("oculto", !foto);
    botonFoto.textContent = foto ? "Cambiar foto" : "Elegir foto";
  };

  const elegirFoto = async (archivo: File): Promise<void> => {
    botonFoto.disabled = true;
    botonFoto.textContent = "Procesando…";
    try {
      foto = await comprimirImagen(archivo);
      pintarFoto();
    } catch (error) {
      aviso(error instanceof Error ? error.message : "No pudimos procesar la imagen.", true);
      pintarFoto();
    } finally {
      botonFoto.disabled = false;
    }
  };

  const alGuardar = (evento: SubmitEvent): void => {
    evento.preventDefault();

    const entrada: EntradaCambio = {
      fecha: fecha.value,
      descripcion: descripcion.value,
      foto,
    };

    const error = validarCambio(entrada);
    if (error) {
      aviso(error, true);
      return;
    }

    const limpio = crearCambio(entrada);
    const cambio: Cambio = existente ? { ...limpio, id: existente.id } : limpio;
    const nuevos = { ...datos, cambios: guardarEnLista(datos.cambios, cambio) };

    if (!guardar(nuevos)) {
      aviso("No hay espacio para guardar. Probá con una foto más chica o borrá algún registro.", true);
      return;
    }

    aviso(existente ? "Cambio actualizado." : "Cambio guardado.");
    navegar(`/detalle/cambio/${cambio.id}`);
  };

  pintarFoto();

  return h(
    "form",
    { class: "pantalla-formulario", onSubmit: alGuardar },
    cabeceraFormulario(existente ? "Editar cambio" : "Nuevo cambio", volver),
    h(
      "main",
      { class: "contenido" },
      campo("Fecha", fecha),
      campo("¿Qué cambió?", descripcion, "Escribí lo que quieras recordar de este momento."),
      h(
        "div",
        { class: "campo" },
        h("span", {}, "Foto"),
        vistaFoto,
        inputFoto,
        h("div", { class: "fila-botones" }, botonFoto, botonQuitar),
        h("p", { class: "ayuda" }, "Opcional. Se guarda una versión comprimida en este dispositivo."),
      ),
      h("p", { class: "nota-local" }, "Nada de esto se envía a internet."),
    ),
    barraGuardar(existente ? "Guardar cambios" : "Guardar cambio"),
  );
}
