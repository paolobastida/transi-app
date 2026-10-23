import { api } from "../api";
import { aFechaInput, fechaTexto, hoy, mesTexto, restarMeses } from "../formato";
import { irADetalleCambio, irATratamiento } from "../navegacion";
import type { EventoTimeline, Usuario } from "../tipos";
import { aviso, cargando, h, vacio } from "../ui";
import { botonFiltro } from "./comunes";

const OPCIONES = [
  { clave: "todo", texto: "Todo" },
  { clave: "mes", texto: "Último mes" },
  { clave: "trimestre", texto: "3 meses" },
  { clave: "anio", texto: "Este año" },
];

export function vistaLineaDeTiempo(usuario: Usuario): HTMLElement {
  let preset = "todo";
  let desde: string | null = null;
  let hasta: string | null = null;

  const lista = h("div", { class: "lista" });
  const chips = h("div", { class: "chips" });
  const desdeInput = h("input", { type: "date", class: "fecha-filtro" });
  const hastaInput = h("input", { type: "date", class: "fecha-filtro" });

  const cargar = async () => {
    lista.replaceChildren(cargando());
    try {
      const eventos = await api.lineaDeTiempo(
        usuario.id,
        desde ?? undefined,
        hasta ?? undefined,
      );
      lista.replaceChildren(...render(eventos, usuario));
    } catch (error) {
      lista.replaceChildren(vacio("⚠️", "No pudimos cargar la línea de tiempo."));
      aviso(String(error), true);
    }
  };

  const pintarChips = () => {
    chips.replaceChildren(
      ...OPCIONES.map((opcion) =>
        botonFiltro(opcion.texto, preset === opcion.clave, () => {
          aplicarPreset(opcion.clave);
        }),
      ),
    );
  };

  const aplicarPreset = (clave: string) => {
    preset = clave;
    const ahora = new Date();
    switch (clave) {
      case "mes":
        desde = aFechaInput(restarMeses(ahora, 1));
        hasta = hoy();
        break;
      case "trimestre":
        desde = aFechaInput(restarMeses(ahora, 3));
        hasta = hoy();
        break;
      case "anio":
        desde = `${ahora.getFullYear()}-01-01`;
        hasta = hoy();
        break;
      default:
        desde = null;
        hasta = null;
    }
    desdeInput.value = desde ?? "";
    hastaInput.value = hasta ?? "";
    pintarChips();
    void cargar();
  };

  const rangoPersonalizado = () => {
    preset = "personalizado";
    desde = desdeInput.value || null;
    hasta = hastaInput.value || null;
    pintarChips();
    void cargar();
  };
  desdeInput.addEventListener("change", rangoPersonalizado);
  hastaInput.addEventListener("change", rangoPersonalizado);

  pintarChips();
  void cargar();

  return h(
    "div",
    { class: "vista" },
    h(
      "div",
      { class: "filtros" },
      chips,
      h(
        "div",
        { class: "rango" },
        h("label", {}, h("span", {}, "Desde"), desdeInput),
        h("label", {}, h("span", {}, "Hasta"), hastaInput),
      ),
    ),
    lista,
  );
}

function render(eventos: EventoTimeline[], usuario: Usuario): HTMLElement[] {
  if (eventos.length === 0) {
    return [
      vacio(
        "🕓",
        "Todavía no hay nada en tu línea de tiempo.\nRegistrá un cambio para empezar.",
      ),
    ];
  }

  const filas: HTMLElement[] = [];
  let mesActual = "";
  eventos.forEach((evento, indice) => {
    const mes = evento.fecha.slice(0, 7);
    if (mes !== mesActual) {
      mesActual = mes;
      filas.push(h("h2", { class: "mes" }, mesTexto(evento.fecha)));
    }
    filas.push(fila(evento, indice === eventos.length - 1, usuario));
  });
  return filas;
}

function fila(evento: EventoTimeline, esUltimo: boolean, usuario: Usuario): HTMLElement {
  const esTratamiento = evento.tipo === "tratamiento";
  const abrir = async () => {
    try {
      if (esTratamiento) {
        const tratamientos = await api.listarTratamientos(usuario.id);
        const tratamiento = tratamientos.find((t) => t.id === evento.referenciaId);
        if (tratamiento) irATratamiento(usuario, tratamiento);
      } else {
        const cambios = await api.listarCambios(usuario.id);
        const cambio = cambios.find((c) => c.id === evento.referenciaId);
        if (cambio) irADetalleCambio(usuario, cambio);
      }
    } catch (error) {
      aviso(String(error), true);
    }
  };

  return h(
    "div",
    { class: "evento-fila" },
    h(
      "div",
      { class: "riel" },
      h("span", { class: `punto ${esTratamiento ? "rosa" : "celeste"}` }),
      esUltimo ? null : h("span", { class: "linea" }),
    ),
    h(
      "article",
      {
        class: "tarjeta evento",
        role: "button",
        tabindex: "0",
        onClick: () => void abrir(),
        onKeydown: (eventoTecla: KeyboardEvent) => {
          if (eventoTecla.key === "Enter" || eventoTecla.key === " ") {
            eventoTecla.preventDefault();
            void abrir();
          }
        },
      },
      h("div", { class: "icono-tarjeta" }, esTratamiento ? "💊" : "✨"),
      h(
        "div",
        { class: "fila-texto" },
        h("strong", {}, evento.titulo),
        h("span", {}, `${fechaTexto(evento.fecha)} · ${evento.detalle}`),
      ),
    ),
  );
}
