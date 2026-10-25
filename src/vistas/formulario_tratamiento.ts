import { actualizar, cargar } from "../almacen";
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
import { icono } from "../iconos";
import {
  sincronizarRecordatorios,
  solicitarPermiso,
  soportaRecordatoriosNativos,
} from "../recordatorios";
import { aviso, h } from "../ui";
import { barraGuardar, cabeceraFormulario, campo } from "./comunes";

interface FilaMedicamento {
  nodo: HTMLElement;
  titulo: HTMLElement;
  /** Id del medicamento que ya existía; se conserva al editar. */
  id?: string;
  nombre: HTMLInputElement;
  dosis: HTMLInputElement;
  frecuencia: HTMLInputElement;
  /** Referencia viva a los inputs de horario de esta fila. */
  horarios: HTMLInputElement[];
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

    const horariosLista = h("div", { class: "horarios-lista" });
    const horarios: HTMLInputElement[] = [];

    const agregarHorario = (valor = ""): void => {
      const entrada = h("input", { type: "time", value: valor });
      const quitarHorario = h(
        "button",
        {
          class: "btn enlace chico",
          type: "button",
          "aria-label": "Quitar este horario",
          onClick: () => {
            const indice = horarios.indexOf(entrada);
            if (indice !== -1) horarios.splice(indice, 1);
            filaHorario.remove();
          },
        },
        "Quitar",
      );
      const filaHorario = h("div", { class: "horario" }, entrada, quitarHorario);
      horarios.push(entrada);
      horariosLista.append(filaHorario);
    };

    for (const horario of medicamento?.horarios ?? []) agregarHorario(horario);

    const nodo = h(
      "section",
      { class: "medicamento" },
      h("div", { class: "medicamento-cabecera" }, titulo, quitar),
      campo("Nombre del medicamento", nombre),
      h(
        "div",
        { class: "fila-campos" },
        campo("Dosis", dosis, "Por ejemplo: 50 mg.", true),
        campo("Frecuencia", frecuencia, "Por ejemplo: cada 7 días.", true),
      ),
      h(
        "div",
        { class: "campo" },
        h(
          "span",
          { class: "campo-etiqueta" },
          "Recordatorio",
          h("em", { class: "campo-opcional" }, "Opcional"),
        ),
        horariosLista,
        h(
          "button",
          { class: "btn secundario chico agregar-horario", type: "button", onClick: () => agregarHorario() },
          icono("mas"),
          "Agregar horario",
        ),
        h("p", { class: "ayuda" }, soportaRecordatoriosNativos()
          ? "Te avisamos a estas horas, aunque la app esté cerrada."
          : "Te avisamos a estas horas mientras la app esté abierta."),
      ),
    );

    const fila: FilaMedicamento = {
      nodo,
      titulo,
      id: medicamento?.id,
      nombre,
      dosis,
      frecuencia,
      horarios,
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

    // Un horario a medias se descartaría en silencio y el recordatorio no existiría.
    const horarioIncompleto = filas.flatMap((fila) => fila.horarios).find((campo) => !campo.value);
    if (horarioIncompleto) {
      horarioIncompleto.focus();
      horarioIncompleto.scrollIntoView({ block: "center", behavior: "smooth" });
      aviso("Completá la hora del recordatorio o quitá esa fila.", true);
      return;
    }

    const entrada: EntradaTratamiento = {
      medicamentos: filas.map((fila) => ({
        id: fila.id,
        nombre: fila.nombre.value,
        dosis: fila.dosis.value,
        frecuencia: fila.frecuencia.value,
        horarios: fila.horarios.map((entradaHorario) => entradaHorario.value),
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
    const guardado = actualizar((actuales) => ({
      ...actuales,
      tratamientos: guardarEnLista(actuales.tratamientos, tratamiento),
    }));

    if (!guardado) {
      aviso(
        "No hay espacio en este navegador. Exportá tus datos desde Ajustes y borrá registros que no necesites.",
        true,
      );
      return;
    }

    aviso(existente ? "Tratamiento actualizado." : "Tratamiento guardado.");
    sincronizarRecordatorios();
    if (tratamiento.medicamentos.some((medicamento) => medicamento.horarios.length > 0)) {
      // Si el sistema pide permiso recién ahora, reprogramamos al concederlo.
      void solicitarPermiso().then(() => sincronizarRecordatorios());
    }
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
        "section",
        { class: "panel" },
        h(
          "div",
          { class: "panel-cabecera" },
          h("h2", { class: "panel-titulo" }, "Medicamentos"),
          h(
            "p",
            { class: "ayuda panel-ayuda" },
            "Podés cargar varios. Todos comparten las fechas y el profesional del tratamiento.",
          ),
        ),
        lista,
        h(
          "button",
          { class: "btn agregar-medicamento", type: "button", onClick: agregarMedicamento },
          icono("mas"),
          "Agregar otro medicamento",
        ),
      ),
      h(
        "section",
        { class: "panel" },
        h("h2", { class: "panel-titulo" }, "Fechas y profesional"),
        h(
          "div",
          { class: "fila-campos" },
          campo("Fecha de inicio", inicio),
          campo("Fecha de fin", fin, "Dejala vacía si seguís con el tratamiento.", true),
        ),
        campo("Profesional", profesional, "Podés incluir la especialidad.", true),
      ),
      h(
        "p",
        { class: "nota-local" },
        "Estos datos son solo para vos: quedan guardados en este dispositivo.",
      ),
    ),
    barraGuardar(existente ? "Guardar cambios" : "Guardar tratamiento"),
  );
}
