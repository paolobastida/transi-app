import { cargar, guardar } from "../almacen";
import { hoy } from "../formato";
import {
  crearTratamiento,
  guardarEnLista,
  validarTratamiento,
  type EntradaTratamiento,
  type Medicamento,
  type Tratamiento,
} from "../modelo";
import { navegar } from "../rutas";
import { aviso, h } from "../ui";
import { barraGuardar, cabeceraFormulario, campo } from "./comunes";

interface FilaMedicamento {
  nodo: HTMLElement;
  titulo: HTMLElement;
  nombre: HTMLInputElement;
  dosis: HTMLInputElement;
  frecuencia: HTMLInputElement;
  quitar: HTMLButtonElement;
}

export function vistaFormularioTratamiento(id?: string): HTMLElement {
  const datos = cargar();
  const existente = id ? datos.tratamientos.find((tratamiento) => tratamiento.id === id) : undefined;

  if (id && !existente) {
    navegar("/");
    return h("div");
  }

  const volver = (): void =>
    existente ? navegar(`/detalle/tratamiento/${existente.id}`) : navegar("/");

  const lista = h("div", { class: "medicamentos" });
  const filas: FilaMedicamento[] = [];

  const reindexar = (): void => {
    filas.forEach((fila, indice) => {
      fila.titulo.textContent = `Medicamento ${indice + 1}`;
      fila.quitar.classList.toggle("oculto", filas.length === 1);
    });
  };

  const agregar = (medicamento?: Medicamento): FilaMedicamento => {
    const nombre = h("input", {
      type: "text",
      value: medicamento?.nombre ?? "",
      placeholder: "Testosterona",
      autocomplete: "off",
      required: true,
    });

    const dosis = h("input", {
      type: "text",
      value: medicamento?.dosis ?? "",
      placeholder: "50 mg",
      autocomplete: "off",
    });

    const frecuencia = h("input", {
      type: "text",
      value: medicamento?.frecuencia ?? "",
      placeholder: "cada 7 días",
      autocomplete: "off",
    });

    const titulo = h("h3", {}, "Medicamento");
    const quitar = h(
      "button",
      {
        class: "btn peligro chico",
        type: "button",
        onClick: () => quitarFila(fila),
      },
      "Quitar",
    );

    const nodo = h(
      "section",
      { class: "medicamento" },
      h("div", { class: "medicamento-cabecera" }, titulo, quitar),
      campo("Nombre", nombre),
      h(
        "div",
        { class: "fila-campos" },
        campo("Dosis", dosis),
        campo("Frecuencia", frecuencia),
      ),
    );

    const fila: FilaMedicamento = {
      nodo,
      titulo,
      nombre,
      dosis,
      frecuencia,
      quitar,
    };

    filas.push(fila);
    lista.append(nodo);
    reindexar();
    return fila;
  };

  const quitarFila = (fila: FilaMedicamento): void => {
    if (filas.length === 1) return;
    const indice = filas.indexOf(fila);
    if (indice === -1) return;
    filas.splice(indice, 1);
    fila.nodo.remove();
    reindexar();
  };

  const inicio = h("input", {
    type: "date",
    value: existente?.inicio ?? hoy(),
    required: true,
  });
  const fin = h("input", { type: "date", value: existente?.fin ?? "" });
  const profesional = h("input", {
    type: "text",
    value: existente?.profesional ?? "",
    placeholder: "Dra. Paz Ruiz · Endocrinología",
    autocomplete: "off",
  });

  for (const medicamento of existente?.medicamentos ?? []) agregar(medicamento);
  if (filas.length === 0) agregar();

  const agregarMedicamento = (): void => {
    const fila = agregar();
    fila.nombre.focus();
    fila.nodo.scrollIntoView({ block: "nearest", behavior: "smooth" });
  };

  const alGuardar = (evento: SubmitEvent): void => {
    evento.preventDefault();

    const entrada: EntradaTratamiento = {
      medicamentos: filas.map((fila) => ({
        nombre: fila.nombre.value,
        dosis: fila.dosis.value,
        frecuencia: fila.frecuencia.value,
      })),
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
      h(
        "div",
        { class: "seccion-formulario" },
        h("h2", {}, "Medicamentos"),
        h(
          "p",
          { class: "ayuda" },
          "Podés cargar varios. Todos comparten las fechas y el profesional del tratamiento.",
        ),
      ),
      lista,
      h(
        "button",
        { class: "btn agregar-medicamento", type: "button", onClick: agregarMedicamento },
        "＋ Agregar otro medicamento",
      ),
      h("h2", { class: "seccion-formulario" }, "Fechas y profesional"),
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
