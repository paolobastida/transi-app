import { borrarTodo, cargar, guardar, normalizar, serializar } from "../almacen";
import { hoy } from "../formato";
import { datosDemo } from "../modelo";
import { navegar } from "../rutas";
import { icono } from "../iconos";
import { aviso, confirmar, h } from "../ui";
import { cabeceraVista } from "./comunes";

export function vistaAjustes(): HTMLElement {
  const datos = cargar();
  const total = datos.tratamientos.length + datos.cambios.length;
  const peso = new Blob([JSON.stringify(datos)]).size;
  const textoPeso = peso < 1024 ? `${peso} B` : `${Math.round(peso / 1024)} KB`;

  const exportar = (): void => {
    const url = URL.createObjectURL(new Blob([serializar(datos)], { type: "application/json" }));
    const enlace = h("a", { href: url, download: `transi-${hoy()}.json` });
    enlace.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
    aviso("Descargamos tu archivo de respaldo.");
  };

  const inputImportar = h("input", {
    type: "file",
    accept: "application/json,.json",
    class: "oculto",
    onChange: (evento: Event) => {
      const archivo = (evento.target as HTMLInputElement).files?.[0];
      if (archivo) void importar(archivo);
    },
  });

  const importar = async (archivo: File): Promise<void> => {
    try {
      const leido = normalizar(JSON.parse(await archivo.text()));
      if (!leido) throw new Error("El archivo no parece un respaldo de Transi.");
      const cantidad = leido.tratamientos.length + leido.cambios.length;
      const etiqueta = cantidad === 1 ? "registro" : "registros";
      if (!confirmar(`Se van a reemplazar tus datos actuales por ${cantidad} ${etiqueta} del archivo. ¿Seguir?`)) {
        return;
      }
      if (!guardar(leido)) throw new Error("No hay espacio para importar estos datos.");
      aviso("Datos importados.");
      navegar("/ajustes");
    } catch (error) {
      aviso(error instanceof Error ? error.message : "No pudimos leer el archivo.", true);
    }
  };

  const cargarDemo = (): void => {
    if (total > 0 && !confirmar("Esto reemplaza lo que tenés cargado por datos de ejemplo. ¿Seguir?")) {
      return;
    }
    if (!guardar(datosDemo())) {
      aviso("No pudimos cargar los datos de ejemplo.", true);
      return;
    }
    aviso("Datos de ejemplo cargados.");
    navegar("/");
  };

  const borrar = (): void => {
    if (!confirmar("¿Borrar todos tus datos de este dispositivo? Esta acción no se puede deshacer.")) return;
    if (!borrarTodo()) {
      aviso("No pudimos borrar los datos.", true);
      return;
    }
    aviso("Borramos todos los datos.");
    navegar("/");
  };

  return h(
    "div",
    { class: "pantalla-detalle" },
    cabeceraVista("Ajustes", () => navegar("/")),
    h(
      "main",
      { class: "contenido" },
      h(
        "section",
        { class: "tarjeta ficha" },
        h("h2", {}, "Tus datos"),
        h(
          "p",
          { class: "sub" },
          "Transi no tiene cuentas ni servidores. Todo lo que registrás se guarda en este navegador, en tu dispositivo.",
        ),
        h(
          "dl",
          { class: "datos" },
          fila("Tratamientos", String(datos.tratamientos.length)),
          fila("Cambios", String(datos.cambios.length)),
          fila("Espacio usado", textoPeso),
        ),
      ),
      h(
        "section",
        { class: "tarjeta ficha" },
        h("h2", {}, "Llevarte tus datos"),
        h(
          "p",
          { class: "sub" },
          "Descargá un archivo JSON para guardarlo donde quieras. Podés volver a importarlo en este u otro dispositivo.",
        ),
        h(
          "div",
          { class: "fila-botones" },
          h(
            "button",
            { class: "btn secundario", type: "button", onClick: exportar },
            icono("descargar"),
            "Exportar",
          ),
          h(
            "button",
            { class: "btn secundario", type: "button", onClick: () => inputImportar.click() },
            icono("subir"),
            "Importar",
          ),
          inputImportar,
        ),
      ),
      h(
        "section",
        { class: "tarjeta ficha" },
        h("h2", {}, "Probar la app"),
        h("p", { class: "sub" }, "Cargá un par de registros ficticios para ver cómo se ve todo."),
        h(
          "div",
          { class: "fila-botones" },
          h(
            "button",
            { class: "btn secundario", type: "button", onClick: cargarDemo },
            icono("chispa"),
            "Cargar datos de ejemplo",
          ),
        ),
      ),
      h(
        "section",
        { class: "tarjeta ficha" },
        h("h2", {}, "Zona sensible"),
        h("p", { class: "sub" }, "Esto borra todos los registros de este dispositivo. No hay copia en la nube."),
        h(
          "div",
          { class: "fila-botones" },
          h(
            "button",
            { class: "btn peligro", type: "button", onClick: borrar },
            icono("basura"),
            "Borrar todos mis datos",
          ),
        ),
      ),
      h("p", { class: "pie" }, `Transi · versión 2.1 · ${total} ${total === 1 ? "registro" : "registros"} en este dispositivo`),
    ),
  );
}

function fila(etiqueta: string, valor: string): HTMLElement {
  return h("div", { class: "dato" }, h("dt", {}, etiqueta), h("dd", {}, valor));
}
