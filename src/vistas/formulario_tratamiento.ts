import { cargar, guardar } from "../almacen";
import { hoy } from "../formato";
import {
  crearTratamiento,
  guardarEnLista,
  validarTratamiento,
  type EntradaTratamiento,
  type Tratamiento,
} from "../modelo";
import { navegar } from "../rutas";
import { aviso, h } from "../ui";
import { barraGuardar, cabeceraFormulario, campo } from "./comunes";

export function vistaFormularioTratamiento(id?: string): HTMLElement {
  const datos = cargar();
  const existente = id ? datos.tratamientos.find((tratamiento) => tratamiento.id === id) : undefined;

  if (id && !existente) {
    navegar("/");
    return h("div");
  }

  const volver = (): void =>
    existente ? navegar(`/detalle/tratamiento/${existente.id}`) : navegar("/");

  const nombre = h("input", {
    type: "text",
    value: existente?.nombre ?? "",
    placeholder: "Testosterona",
    autocomplete: "off",
    required: true,
  });

  const dosis = h("input", {
    type: "text",
    value: existente?.dosis ?? "",
    placeholder: "50 mg",
    autocomplete: "off",
  });

  const frecuencia = h("input", {
    type: "text",
    value: existente?.frecuencia ?? "",
    placeholder: "cada 7 días",
    autocomplete: "off",
  });

  const inicio = h("input", {
    type: "date",
    value: existente?.inicio ?? hoy(),
    required: true,
  });

  const fin = h("input", {
    type: "date",
    value: existente?.fin ?? "",
  });

  const profesional = h("input", {
    type: "text",
    value: existente?.profesional ?? "",
    placeholder: "Dra. Paz Ruiz · Endocrinología",
    autocomplete: "off",
  });

  const alGuardar = (evento: SubmitEvent): void => {
    evento.preventDefault();

    const entrada: EntradaTratamiento = {
      nombre: nombre.value,
      dosis: dosis.value,
      frecuencia: frecuencia.value,
      inicio: inicio.value,
      fin: fin.value || null,
      profesional: profesional.value || null,
    };

    const error = validarTratamiento(entrada);
    if (error) {
      aviso(error, true);
      return;
    }

    const limpio = crearTratamiento(entrada);
    const tratamiento: Tratamiento = existente ? { ...limpio, id: existente.id } : limpio;
    const nuevos = {
      ...datos,
      tratamientos: guardarEnLista(datos.tratamientos, tratamiento),
    };

    if (!guardar(nuevos)) {
      aviso("No hay espacio para guardar. Probá borrar alguna foto desde Ajustes.", true);
      return;
    }

    aviso(existente ? "Tratamiento actualizado." : "Tratamiento guardado.");
    navegar(`/detalle/tratamiento/${tratamiento.id}`);
  };

  return h(
    "form",
    { class: "pantalla-formulario", onSubmit: alGuardar },
    cabeceraFormulario(existente ? "Editar tratamiento" : "Nuevo tratamiento", volver),
    h(
      "main",
      { class: "contenido" },
      campo("Medicamento", nombre, "El nombre que te resulte más claro."),
      h(
        "div",
        { class: "fila-campos" },
        campo("Dosis", dosis, "Opcional."),
        campo("Frecuencia", frecuencia, "Opcional."),
      ),
      h(
        "div",
        { class: "fila-campos" },
        campo("Inicio", inicio),
        campo("Fin", fin, "Dejala vacía si seguís con el tratamiento."),
      ),
      campo("Profesional", profesional, "Opcional. Podés incluir la especialidad."),
      h(
        "p",
        { class: "nota-local" },
        "Estos datos son solo para vos: quedan guardados en este dispositivo.",
      ),
    ),
    barraGuardar(existente ? "Guardar cambios" : "Guardar tratamiento"),
  );
}
