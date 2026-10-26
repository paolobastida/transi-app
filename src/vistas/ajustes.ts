import {
  borrarRespaldoRoto,
  borrarTodo,
  cargar,
  datosAnonimos,
  guardar,
  normalizar,
  respaldoRoto,
  serializar,
  tieneDatos,
} from "../almacen";
import {
  entrarConPerfil,
  importarDatosAnonimos,
  perfilActual,
  salirDeCuenta,
} from "../auth";
import { etiquetaProveedor, iniciales, nombreVisible, type Perfil } from "../perfil";
import { alSalir } from "../ciclo_vida";
import { hoy } from "../formato";
import { montarProveedores } from "../botones_cuenta";
import { datosDemo } from "../modelo";
import { alCambiarInstalacion, pedirInstalacion } from "../pwa";
import {
  estadoRecordatorios,
  probarRecordatorio,
  sincronizarRecordatorios,
  solicitarPermiso,
} from "../recordatorios";
import { navegar } from "../rutas";
import { icono } from "../iconos";
import { aviso, confirmar, descargar, h } from "../ui";
import { cabeceraVista } from "./comunes";

export function vistaAjustes(): HTMLElement {
  const datos = cargar();
  const total = datos.tratamientos.length + datos.cambios.length;
  const peso = new Blob([JSON.stringify(datos)]).size;
  const textoPeso = peso < 1024 ? `${peso} B` : `${Math.round(peso / 1024)} KB`;
  const perfil = perfilActual();
  const hayDatosAnonimos = tieneDatos(datosAnonimos());
  const cuentaVacia = !tieneDatos(datos);

  const exportar = (): void => {
    descargar(`transi-${hoy()}.json`, serializar(datos), "application/json");
    aviso("Descargamos tu archivo de respaldo.");
  };

  const inputImportar = h("input", {
    type: "file",
    accept: "application/json,.json",
    class: "oculto",
    onChange: (evento: Event) => {
      const objetivo = evento.target as HTMLInputElement;
      const archivo = objetivo.files?.[0];
      // Limpio ya: si no, elegir el mismo archivo tras cancelar no dispara change.
      objetivo.value = "";
      if (archivo) void importar(archivo);
    },
  });

  const importar = async (archivo: File): Promise<void> => {
    try {
      const crudo: unknown = JSON.parse(await archivo.text());
      const leido = normalizar(crudo, { respaldo: true });
      if (!leido) {
        throw new Error("El archivo no es un respaldo de Transi, o viene de una versión más nueva.");
      }

      const enElArchivo = contarRegistros(crudo);
      const validos = leido.tratamientos.length + leido.cambios.length;
      const descartados = Math.max(0, enElArchivo - validos);

      const partes = [
        `Se van a reemplazar tus datos actuales por ${validos} ${validos === 1 ? "registro" : "registros"} del archivo.`,
      ];
      if (descartados > 0) {
        partes.push(
          `${descartados} ${descartados === 1 ? "entrada no parece válida y se descarta" : "entradas no parecen válidas y se descartan"}.`,
        );
      }
      if (!confirmar(`${partes.join(" ")} ¿Seguir?`)) return;

      if (!guardar(leido)) throw new Error("No hay espacio para importar estos datos.");
      sincronizarRecordatorios();
      aviso(descartados > 0 ? "Datos importados, con entradas descartadas." : "Datos importados.");
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
    sincronizarRecordatorios();
    aviso("Datos de ejemplo cargados.");
    navegar("/");
  };

  const borrar = (): void => {
    const mensaje = perfil
      ? "¿Borrar los registros de esta cuenta en este dispositivo? Las demás cuentas no se tocan."
      : "¿Borrar todos tus datos de este dispositivo?";
    if (!confirmar(`${mensaje} Esta acción no se puede deshacer.`)) return;
    if (!borrarTodo()) {
      aviso("No pudimos borrar los datos.", true);
      return;
    }
    sincronizarRecordatorios();
    aviso(perfil ? "Borramos los datos de esta cuenta." : "Borramos todos los datos.");
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
        "p",
        { class: "intro" },
        "Tus datos, respaldos, recordatorios y opciones de la app. Nada se comparte con terceros.",
      ),
      h(
        "section",
        { class: "tarjeta ficha" },
        h("h2", {}, "Tus datos"),
        h(
          "p",
          { class: "sub" },
          "Todo lo que registrás se guarda en este navegador, en tu dispositivo. Sin cuenta también funciona.",
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
      seccionRespaldoRoto(),
      seccionRecordatorios(),
      seccionCuenta({ hayDatosAnonimos, cuentaVacia }),
      seccionInstalar(),
      h(
        "section",
        { class: "tarjeta ficha" },
        h("h2", {}, "Probar la app"),
        h("p", { class: "sub" }, "¿Querés ver cómo se ve con datos de ejemplo?"),
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
      seccionAyuda(),
      h(
        "section",
        { class: "tarjeta ficha" },
        h("h2", {}, "Empezar de cero"),
        h(
          "p",
          { class: "sub" },
          perfil
            ? "Esto borra los registros de esta cuenta en este dispositivo. Las otras cuentas no se tocan. " +
              "Si querés conservarlos, exportá un respaldo antes."
            : "Esto borra todos los registros de este dispositivo. No hay copia en la nube. " +
              "Si querés conservarlos, exportá un respaldo antes.",
        ),
        h(
          "div",
          { class: "fila-botones" },
          h(
            "button",
            { class: "btn peligro", type: "button", onClick: borrar },
            icono("basura"),
            perfil ? "Borrar los datos de esta cuenta" : "Borrar todos mis datos",
          ),
        ),
      ),
      h("p", { class: "pie" }, `Transi · versión 2.3 · ${total} ${total === 1 ? "registro" : "registros"} en este dispositivo`),
    ),
  );
}

function fila(etiqueta: string, valor: string): HTMLElement {
  return h("div", { class: "dato" }, h("dt", {}, etiqueta), h("dd", {}, valor));
}

/** Cuántos registros trae un objeto crudo, antes de validarlo. */
function contarRegistros(valor: unknown): number {
  if (!valor || typeof valor !== "object") return 0;
  const bruto = valor as Record<string, unknown>;
  const cuenta = (clave: string): number => (Array.isArray(bruto[clave]) ? bruto[clave].length : 0);
  return cuenta("tratamientos") + cuenta("cambios");
}

/**
 * Solo aparece si quedó un respaldo ilegible: `cargar()` lo aparta antes de que
 * un guardado nuevo lo pise, y acá se ofrece descargarlo o descartarlo.
 */
function seccionRespaldoRoto(): HTMLElement | null {
  const crudo = respaldoRoto();
  if (crudo === null) return null;

  const peso = new Blob([crudo]).size;
  const textoPeso = peso < 1024 ? `${peso} B` : `${Math.round(peso / 1024)} KB`;

  return h(
    "section",
    { class: "tarjeta ficha ficha-rota" },
    h("h2", {}, "Respaldo dañado"),
    h(
      "p",
      { class: "sub" },
      `Encontramos una copia previa de tus datos que el navegador no pudo leer (${textoPeso}). ` +
        "La guardamos aparte para que un registro nuevo no la pise. Descargala: quizás se recupera en otro dispositivo o a mano.",
    ),
    h(
      "div",
      { class: "fila-botones" },
      h(
        "button",
        {
          class: "btn secundario",
          type: "button",
          onClick: () => {
            descargar(`transi-respaldo-danado-${hoy()}.txt`, crudo, "text/plain");
            aviso("Descargamos la copia del respaldo dañado.");
          },
        },
        icono("descargar"),
        "Descargar copia",
      ),
      h(
        "button",
        {
          class: "btn peligro",
          type: "button",
          onClick: () => {
            if (!confirmar("¿Descartar la copia del respaldo dañado? No se puede deshacer.")) return;
            if (!borrarRespaldoRoto()) {
              aviso("No pudimos descartar la copia.", true);
              return;
            }
            aviso("Descartamos la copia dañada.");
            navegar("/ajustes");
          },
        },
        icono("basura"),
        "Descartar copia",
      ),
    ),
  );
}

/** Identidad opcional. La cuenta solo separa los datos por perfil en ESTE
 *  dispositivo: no hay servidor, así que seguir sin cuenta funciona igual. */
function seccionCuenta(opciones: { hayDatosAnonimos: boolean; cuentaVacia: boolean }): HTMLElement {
  const perfil = perfilActual();

  if (!perfil) return cuentaSinSesion();

  const salida = h(
    "button",
    {
      class: "btn secundario",
      type: "button",
      onClick: () => {
        salirDeCuenta();
        sincronizarRecordatorios();
        aviso("Saliste de tu cuenta. Tus datos quedaron guardados en este dispositivo.");
        navegar("/ajustes");
      },
    },
    "Salir de cuenta",
  );

  const seccionConCuenta = h(
    "section",
    { class: "tarjeta ficha" },
    h("h2", {}, "Tu cuenta"),
    h(
      "div",
      { class: "cuenta-ficha" },
      h("span", { class: "cuenta-avatar", "aria-hidden": "true" }, iniciales(perfil)),
      h(
        "div",
        { class: "cuenta-texto" },
        h("strong", {}, nombreVisible(perfil)),
        h("span", { class: "cuenta-email" }, perfil.email),
        h("span", { class: "cuenta-proveedor" }, `Cuenta de ${etiquetaProveedor(perfil.proveedor)}`),
      ),
    ),
    h(
      "p",
      { class: "sub" },
      "Tus registros se guardan separados por cuenta en este dispositivo. El proveedor de la cuenta no recibe nada de lo que cargás.",
    ),
    h("div", { class: "fila-botones" }, salida),
  );

  // La cuenta recién activada está vacía y quedaron registros hechos sin cuenta:
  // se ofrecen una vez, sin borrar nada del camino anónimo.
  if (opciones.cuentaVacia && opciones.hayDatosAnonimos) {
    seccionConCuenta.append(
      h(
        "div",
        { class: "cuenta-migrar" },
        h("p", { class: "sub" }, "Tenés registros hechos antes de entrar con una cuenta. ¿Los llevás a tu cuenta?"),
        h(
          "div",
          { class: "fila-botones" },
          h(
            "button",
            {
              class: "btn secundario",
              type: "button",
              onClick: () => {
                if (importarDatosAnonimos()) {
                  sincronizarRecordatorios();
                  aviso("Tus registros pasaron a tu cuenta.");
                  navegar("/ajustes");
                } else {
                  aviso("No pudimos copiar los registros sin cuenta.", true);
                }
              },
            },
            icono("subir"),
            "Llevarlos a mi cuenta",
          ),
        ),
      ),
    );
  }

  return seccionConCuenta;

  function cuentaSinSesion(): HTMLElement {
    const contenedor = h("div", { class: "cuenta-contenedor" });

    const seccion = h(
      "section",
      { class: "tarjeta ficha" },
      h("h2", {}, "Tu cuenta (opcional)"),
      h(
        "p",
        { class: "sub" },
        "Opcional y sin servidor: entrá con tu email o una cuenta de Google o Apple solo para " +
          "separar tus datos por perfil en este dispositivo. Seguí sin cuenta y no se pierde nada.",
      ),
      contenedor,
    );

    montarProveedores(contenedor, {
      alEntrar: (perfilEntrado: Perfil) => {
        entrarConPerfil(perfilEntrado);
        sincronizarRecordatorios();
        aviso(`Entraste con ${nombreVisible(perfilEntrado)}.`);
        // Re-renderiza: cambió el espacio de datos, así que cambian los contadores.
        navegar("/ajustes");
      },
      alError: (mensaje: string) => aviso(mensaje, true),
    });

    return seccion;
  }
}

function seccionRecordatorios(): HTMLElement {
  const detalle = h("p", { class: "sub" }, "Consultando el sistema…");

  const probar = h(
    "button",
    {
      class: "btn secundario oculto",
      type: "button",
      onClick: () => {
        void (async () => {
          const ok = await probarRecordatorio();
          sincronizarRecordatorios();
          aviso(
            ok
              ? "Listo: en 10 segundos debería aparecer el aviso de prueba."
              : "No pudimos programar la prueba. Revisá el permiso de notificaciones.",
            !ok,
          );
          await refrescar();
        })();
      },
    },
    icono("reloj"),
    "Probar aviso",
  );

  const boton = h(
    "button",
    {
      class: "btn secundario oculto",
      type: "button",
      onClick: () => {
        void (async () => {
          const permiso = await solicitarPermiso();
          if (permiso === "concedido") {
            sincronizarRecordatorios();
            aviso("Notificaciones activadas.");
          } else if (permiso === "denegado") {
            aviso("Permití las notificaciones en la configuración del sistema.", true);
          }
          await refrescar();
        })();
      },
    },
    icono("reloj"),
    "Activar notificaciones",
  );

  async function refrescar(): Promise<void> {
    const estado = await estadoRecordatorios();
    boton.classList.toggle("oculto", estado.permiso !== "sin-solicitar");
    probar.classList.toggle("oculto", !estado.nativo || estado.permiso !== "concedido");

    if (estado.nativo) {
      detalle.textContent = {
        concedido:
          estado.programados === 0
            ? "Todavía no hay horarios cargados. Agregalos en cada medicamento."
            : `${estado.programados} ${estado.programados === 1 ? "recordatorio programado" : "recordatorios programados"} en macOS. Suenan aunque Transi esté cerrada.`,
        "sin-solicitar":
          "Activá las notificaciones para que macOS te avise, aunque Transi esté cerrada.",
        denegado:
          "Las notificaciones están bloqueadas. Habilitalas en Ajustes del Sistema → Notificaciones → Transi.",
        "no-soportado": "No pudimos consultar el sistema de notificaciones.",
      }[estado.permiso];
    } else {
      detalle.textContent = {
        concedido:
          "Notificaciones activadas. En el navegador, Transi te avisa mientras la app esté abierta.",
        "sin-solicitar": "Activá las notificaciones para que te avisemos la hora de tu medicación.",
        denegado:
          "Tenés las notificaciones bloqueadas. Habilitalas en la configuración del navegador para que te avisemos.",
        "no-soportado":
          "Tu navegador no muestra notificaciones del sistema: los avisos aparecen dentro de la app.",
      }[estado.permiso];
    }
  }

  void refrescar();

  return h(
    "section",
    { class: "tarjeta ficha" },
    h("h2", {}, "Recordatorios"),
    detalle,
    h(
      "p",
      { class: "sub" },
      "Los horarios se cargan en cada medicamento. En la app de macOS quedan programados en el sistema y suenan aunque esté cerrada. En el navegador, solo mientras la app esté abierta.",
    ),
    h("div", { class: "fila-botones" }, boton, probar),
  );
}

function seccionAyuda(): HTMLElement {
  return h(
    "section",
    { class: "tarjeta ficha" },
    h("h2", {}, "¿Necesitás una mano?"),
    h(
      "p",
      { class: "sub" },
      "Te explicamos qué podés anotar, cómo se guardan tus datos y cómo hacer un respaldo.",
    ),
    h(
      "div",
      { class: "fila-botones" },
      h(
        "button",
        { class: "btn secundario", type: "button", onClick: () => navegar("/ayuda") },
        icono("ayuda"),
        "Abrir la ayuda",
      ),
    ),
  );
}

function seccionInstalar(): HTMLElement {
  const detalle = h("p", { class: "sub" }, "");
  const boton = h(
    "button",
    {
      class: "btn secundario oculto",
      type: "button",
      onClick: () => {
        void (async () => {
          const aceptada = await pedirInstalacion();
          if (!aceptada) {
            aviso("No se instaló la app. Podés intentarlo desde el menú del navegador.");
          }
        })();
      },
    },
    icono("descargar"),
    "Instalar app",
  );

  const seccion = h(
    "section",
    { class: "tarjeta ficha" },
    h("h2", {}, "Instalar la app"),
    detalle,
    h("div", { class: "fila-botones" }, boton),
  );

  const desuscribir = alCambiarInstalacion((estado) => {
    boton.classList.toggle("oculto", estado !== "disponible");
    detalle.textContent = {
      instalada: "Ya estás usando Transi como app instalada.",
      disponible:
        "Instalá Transi para abrirla desde tu pantalla de inicio, con su propio ícono y sin la barra del navegador.",
      ios: "En iPhone o iPad: tocá Compartir y elegí «Añadir a pantalla de inicio».",
      navegador:
        "Podés instalarla desde el menú del navegador: «Instalar app» o «Añadir a pantalla de inicio».",
    }[estado];
  });
  alSalir(desuscribir);

  return seccion;
}
