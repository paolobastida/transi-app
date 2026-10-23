import { api } from "../api";
import { hoy, horaTexto } from "../formato";
import { irAInicio } from "../navegacion";
import type { EntradaTratamiento, Tratamiento, Usuario } from "../tipos";
import { aviso, confirmar, h } from "../ui";

interface Borrador {
  nombre: string;
  dosis: string;
  via: string;
  frecuencia: string;
  presentacion: string;
  indicacion: string;
  recordatorio: number[];
}

const vacio = (): Borrador => ({
  nombre: "",
  dosis: "",
  via: "",
  frecuencia: "",
  presentacion: "",
  indicacion: "",
  recordatorio: [],
});

const desdeTratamiento = (t: Tratamiento): Borrador => ({
  nombre: t.nombre,
  dosis: t.dosis,
  via: t.via ?? "",
  frecuencia: t.frecuencia,
  presentacion: t.presentacion ?? "",
  indicacion: t.indicacion ?? "",
  recordatorio: [...t.recordatorioMinutos],
});

/** Misma regla que la app Flutter: "50 mg" → cantidad 50 + unidad "mg". */
function dosisEstructurada(dosis: string): {
  cantidad: number | null;
  unidad: string | null;
} {
  const coincidencia = /^(\d+(?:[.,]\d+)?)\s*(.*)$/.exec(dosis.trim());
  if (!coincidencia) return { cantidad: null, unidad: null };
  const cantidad = Number(coincidencia[1].replace(",", "."));
  const unidad = coincidencia[2].trim();
  return {
    cantidad: Number.isFinite(cantidad) ? cantidad : null,
    unidad: unidad || null,
  };
}

function campoTexto(
  etiqueta: string,
  valor: string,
  alCambiar: (valor: string) => void,
  extras: Record<string, unknown> = {},
): HTMLElement {
  return h(
    "label",
    { class: "campo" },
    h("span", {}, etiqueta),
    h("input", {
      value: valor,
      onInput: (evento: Event) =>
        alCambiar((evento.target as HTMLInputElement).value),
      ...extras,
    }),
  );
}

export function vistaFormularioTratamiento(
  usuario: Usuario,
  existente?: Tratamiento,
): HTMLElement {
  const editando = existente != null;
  const borradores: Borrador[] = [
    existente ? desdeTratamiento(existente) : vacio(),
  ];

  let fechaInicio = existente?.fechaInicio.slice(0, 10) ?? hoy();
  let fechaFin = existente?.fechaFin?.slice(0, 10) ?? "";
  let profesionalNombre = existente?.profesionalNombre ?? "";
  let profesionalEspecialidad = existente?.profesionalEspecialidad ?? "";

  const contenedor = h("div", { class: "medicamentos" });
  const botonGuardar = h(
    "button",
    { class: "btn primario", onClick: () => void guardar() },
    editando ? "Guardar cambios" : "Guardar",
  );

  const pintar = () => {
    contenedor.replaceChildren(
      ...borradores.map((borrador, indice) => bloque(borrador, indice)),
      editando
        ? h("span")
        : h(
            "button",
            {
              type: "button",
              class: "btn secundario",
              onClick: () => {
                borradores.push(vacio());
                pintar();
              },
            },
            "+ Agregar otro medicamento",
          ),
    );
  };

  function bloque(borrador: Borrador, indice: number): HTMLElement {
    const horas = h(
      "div",
      { class: "chips" },
      ...borrador.recordatorio.map((minutos) =>
        h(
          "span",
          { class: "chip" },
          horaTexto(minutos),
          h(
            "button",
            {
              type: "button",
              class: "chip-x",
              title: "Quitar hora",
              onClick: () => {
                borrador.recordatorio = borrador.recordatorio.filter(
                  (m) => m !== minutos,
                );
                pintar();
              },
            },
            "×",
          ),
        ),
      ),
      h("input", {
        type: "time",
        class: "hora",
        title: "Agregar hora",
        onChange: (evento: Event) => {
          const valor = (evento.target as HTMLInputElement).value;
          if (!valor) return;
          const [hh, mm] = valor.split(":").map(Number);
          const minutos = hh * 60 + mm;
          if (!borrador.recordatorio.includes(minutos)) {
            borrador.recordatorio = [...borrador.recordatorio, minutos].sort(
              (a, b) => a - b,
            );
            pintar();
          }
        },
      }),
    );

    return h(
      "section",
      { class: "tarjeta medicamento" },
      h(
        "div",
        { class: "medicamento-cabecera" },
        h("h3", {}, `Medicamento ${indice + 1}`),
        !editando && borradores.length > 1
          ? h(
              "button",
              {
                type: "button",
                class: "btn icono",
                title: "Quitar medicamento",
                onClick: () => {
                  borradores.splice(indice, 1);
                  pintar();
                },
              },
              "×",
            )
          : null,
      ),
      campoTexto("Nombre del medicamento", borrador.nombre, (v) => {
        borrador.nombre = v;
      }),
      campoTexto(
        "Dosis",
        borrador.dosis,
        (v) => {
          borrador.dosis = v;
        },
        { placeholder: "Ej. 50 mg, 1 tableta, 1 parche" },
      ),
      campoTexto(
        "Vía (opcional)",
        borrador.via,
        (v) => {
          borrador.via = v;
        },
        { placeholder: "Ej. oral, inyectable, transdérmica" },
      ),
      campoTexto(
        "Frecuencia",
        borrador.frecuencia,
        (v) => {
          borrador.frecuencia = v;
        },
        { placeholder: "Ej. cada día, 2 veces por semana" },
      ),
      h(
        "details",
        { class: "detalles" },
        h("summary", {}, "Más detalles (opcional)"),
        campoTexto(
          "Presentación",
          borrador.presentacion,
          (v) => {
            borrador.presentacion = v;
          },
          { placeholder: "Ej. cipionato 200 mg/mL" },
        ),
        campoTexto(
          "Indicación",
          borrador.indicacion,
          (v) => {
            borrador.indicacion = v;
          },
          { placeholder: "Ej. feminización, bloqueo de andrógenos" },
        ),
      ),
      h(
        "div",
        { class: "campo" },
        h("span", {}, "Recordatorio (opcional)"),
        h(
          "p",
          { class: "ayuda" },
          "Te avisamos todos los días a las horas que elijas.",
        ),
        horas,
      ),
    );
  }

  const entradaDe = (borrador: Borrador): EntradaTratamiento => {
    const { cantidad, unidad } = dosisEstructurada(borrador.dosis);
    return {
      nombre: borrador.nombre.trim(),
      dosis: borrador.dosis.trim(),
      frecuencia: borrador.frecuencia.trim(),
      fechaInicio,
      fechaFin: fechaFin || null,
      via: borrador.via.trim() || null,
      presentacion: borrador.presentacion.trim() || null,
      dosisCantidad: cantidad,
      dosisUnidad: unidad,
      indicacion: borrador.indicacion.trim() || null,
      profesionalNombre: profesionalNombre.trim() || null,
      profesionalEspecialidad: profesionalEspecialidad.trim() || null,
      recordatorioMinutos: borrador.recordatorio,
    };
  };

  const guardar = async () => {
    for (const [indice, borrador] of borradores.entries()) {
      if (!borrador.nombre.trim()) {
        aviso(`Medicamento ${indice + 1}: falta el nombre`, true);
        return;
      }
      if (!borrador.dosis.trim()) {
        aviso(`Medicamento ${indice + 1}: falta la dosis`, true);
        return;
      }
      if (!borrador.frecuencia.trim()) {
        aviso(`Medicamento ${indice + 1}: falta la frecuencia`, true);
        return;
      }
    }
    if (fechaFin && fechaFin < fechaInicio) {
      aviso("La fecha de fin no puede ser anterior a la de inicio", true);
      return;
    }

    botonGuardar.setAttribute("disabled", "true");
    try {
      if (borradores.some((b) => b.recordatorio.length > 0)) {
        await api.solicitarPermisoNotificaciones().catch(() => false);
      }

      if (editando && existente) {
        await api.actualizarTratamiento({
          ...existente,
          ...entradaDe(borradores[0]),
        });
      } else {
        for (const borrador of borradores) {
          await api.crearTratamiento(usuario.id, entradaDe(borrador));
        }
      }
      irAInicio(usuario, 1);
    } catch (error) {
      aviso(String(error), true);
    } finally {
      botonGuardar.removeAttribute("disabled");
    }
  };

  const desactivar = async () => {
    if (!existente) return;
    if (!confirmar("¿Ocultar este tratamiento? No se borra: deja de mostrarse."))
      return;
    try {
      await api.desactivarTratamiento(existente.id, usuario.id);
      irAInicio(usuario, 1);
    } catch (error) {
      aviso(String(error), true);
    }
  };

  pintar();

  return h(
    "div",
    { class: "pantalla-formulario" },
    h(
      "header",
      { class: "cabecera" },
      h(
        "button",
        { class: "btn icono", title: "Volver", onClick: () => irAInicio(usuario, 1) },
        "‹",
      ),
      h(
        "span",
        { class: "titulo" },
        editando ? "Editar tratamiento" : "Nuevo tratamiento",
      ),
      editando
        ? h(
            "button",
            {
              class: "btn icono",
              title: "Ocultar tratamiento",
              onClick: () => void desactivar(),
            },
            "🗑",
          )
        : h("span"),
    ),
    h(
      "div",
      { class: "contenido" },
      contenedor,
      h("h3", { class: "seccion" }, "Fechas"),
      h(
        "label",
        { class: "campo" },
        h("span", {}, "Inicio"),
        h("input", {
          type: "date",
          value: fechaInicio,
          max: hoy(),
          onChange: (evento: Event) => {
            fechaInicio = (evento.target as HTMLInputElement).value;
          },
        }),
      ),
      h(
        "label",
        { class: "campo" },
        h("span", {}, "Fin (opcional)"),
        h("input", {
          type: "date",
          value: fechaFin,
          max: hoy(),
          onChange: (evento: Event) => {
            fechaFin = (evento.target as HTMLInputElement).value;
          },
        }),
      ),
      h("h3", { class: "seccion" }, "Profesional (opcional)"),
      campoTexto(
        "Nombre",
        profesionalNombre,
        (v) => {
          profesionalNombre = v;
        },
        { placeholder: "Ej. Dra. García" },
      ),
      campoTexto(
        "Especialidad",
        profesionalEspecialidad,
        (v) => {
          profesionalEspecialidad = v;
        },
        { placeholder: "Escribí lo que sea, o dejalo vacío" },
      ),
    ),
    h("div", { class: "barra-guardar" }, botonGuardar),
  );
}
