import { describe, expect, it } from "vitest";
import {
  agruparPorDia,
  aplicacionesDe,
  aplicacionesHoy,
  aplicacionesProximas,
  aplicacionesRecientes,
  cadenciaDe,
  diasDeAplicacion,
  esDiaDeAplicacion,
  frecuenciaInterpretable,
  parsearFrecuencia,
} from "../src/aplicaciones";
import { crearTratamiento, type Datos, type Medicamento, type Tratamiento } from "../src/modelo";

/** El medicamento de un tratamiento de ejemplo. */
function med(frecuencia: string, nombre = "Testosterona"): Medicamento {
  return (tr({ frecuencia, nombre, inicio: "2026-01-10" }).medicamentos[0] ?? undefined) as Medicamento;
}

/** Tratamiento de ejemplo: una frecuencia, unos horarios y un inicio. */
function tr(opciones: {
  frecuencia: string;
  horarios?: string[];
  inicio: string;
  fin?: string | null;
  nombre?: string;
}): Tratamiento {
  return crearTratamiento({
    medicamentos: [
      {
        id: "m1",
        nombre: opciones.nombre ?? "Testosterona",
        dosis: "50 mg",
        frecuencia: opciones.frecuencia,
        horarios: opciones.horarios ?? ["09:00"],
      },
    ],
    inicio: opciones.inicio,
    fin: opciones.fin ?? null,
    profesional: null,
  });
}

function datos(tratamientos: Tratamiento[]): Datos {
  return { version: 4, tratamientos, cambios: [] };
}

describe("interpretar la frecuencia", () => {
  it("lee las frecuencias en días", () => {
    expect(parsearFrecuencia("cada 7 días")).toEqual({ tipo: "dias", cada: 7 });
    expect(parsearFrecuencia("cada 15 dias")).toEqual({ tipo: "dias", cada: 15 });
    expect(parsearFrecuencia("cada dos semanas")).toEqual({ tipo: "dias", cada: 14 });
    expect(parsearFrecuencia("cada 2 semanas")).toEqual({ tipo: "dias", cada: 14 });
    expect(parsearFrecuencia("cada 3 meses")).toEqual({ tipo: "meses", cada: 3 });
  });

  it("las frecuencias en horas o minutos de menos de un día son diarias", () => {
    expect(parsearFrecuencia("cada 12 horas")).toEqual({ tipo: "dias", cada: 1 });
    expect(parsearFrecuencia("cada 24 horas")).toEqual({ tipo: "dias", cada: 1 });
    expect(parsearFrecuencia("cada 8 horas")).toEqual({ tipo: "dias", cada: 1 });
    expect(parsearFrecuencia("cada 15 minutos")).toEqual({ tipo: "dias", cada: 1 });
  });

  it("las horas en múltiplos de 24 se convierten en días", () => {
    expect(parsearFrecuencia("cada 48 horas")).toEqual({ tipo: "dias", cada: 2 });
    expect(parsearFrecuencia("cada 168 horas")).toEqual({ tipo: "dias", cada: 7 });
  });

  it("lee las dichas con palabras", () => {
    expect(parsearFrecuencia("todos los días")).toEqual({ tipo: "dias", cada: 1 });
    expect(parsearFrecuencia("diario")).toEqual({ tipo: "dias", cada: 1 });
    expect(parsearFrecuencia("semanal")).toEqual({ tipo: "dias", cada: 7 });
    expect(parsearFrecuencia("mensual")).toEqual({ tipo: "meses", cada: 1 });
    expect(parsearFrecuencia("quincenal")).toEqual({ tipo: "dias", cada: 15 });
    expect(parsearFrecuencia("una vez al día")).toEqual({ tipo: "dias", cada: 1 });
  });

  it("no se acomoda a mayúsculas, acentos ni punto final", () => {
    expect(parsearFrecuencia("CADA 7 DÍAS")).toEqual({ tipo: "dias", cada: 7 });
    expect(parsearFrecuencia("  cada   7   dias.  ")).toEqual({ tipo: "dias", cada: 7 });
  });

  it("lee la frecuencia aunque vaya acompañada de presentación o vía", () => {
    expect(parsearFrecuencia("cada 14 días · intramuscular")).toEqual({ tipo: "dias", cada: 14 });
    expect(parsearFrecuencia("250 mg / 5 ml · cada 14 días")).toEqual({ tipo: "dias", cada: 14 });
    expect(parsearFrecuencia("cada 21 días (Nebido)")).toEqual({ tipo: "dias", cada: 21 });
    expect(parsearFrecuencia("cada 7 días · por la mañana")).toEqual({ tipo: "dias", cada: 7 });
    expect(parsearFrecuencia("cada 12 horas después de comer")).toEqual({ tipo: "dias", cada: 1 });
  });

  it("acompañar la frecuencia no esconde una que sigue estando mal", () => {
    expect(parsearFrecuencia("cada 36 horas por la mañana")).toBeNull();
    expect(parsearFrecuencia("cada tanto, cuando puedo")).toBeNull();
  });

  it("devuelve null cuando no entiende, sin inventar", () => {
    expect(parsearFrecuencia("cada 36 horas")).toBeNull();
    expect(parsearFrecuencia("cada 2000 minutos")).toBeNull();
    expect(parsearFrecuencia("cada tanto")).toBeNull();
    expect(parsearFrecuencia("según me sienta")).toBeNull();
    expect(parsearFrecuencia("")).toBeNull();
    expect(parsearFrecuencia("   ")).toBeNull();
    expect(parsearFrecuencia("cada 0 días")).toBeNull();
    expect(parsearFrecuencia("cada -2 días")).toBeNull();
  });

  it("lee la frecuencia aunque vaya con la dosis u otras aclaraciones", () => {
    // Así como se escriben en la vida real, no solo en el placeholder.
    expect(parsearFrecuencia("cada 14 días · intramuscular")).toEqual({ tipo: "dias", cada: 14 });
    expect(parsearFrecuencia("250 mg / 5 ml · cada 14 días")).toEqual({ tipo: "dias", cada: 14 });
    expect(parsearFrecuencia("cada 14 días (IM)")).toEqual({ tipo: "dias", cada: 14 });
    expect(parsearFrecuencia("cada 21 días (Nebido)")).toEqual({ tipo: "dias", cada: 21 });
    expect(parsearFrecuencia("cada 14 días.")).toEqual({ tipo: "dias", cada: 14 });
    expect(parsearFrecuencia("Intramuscular, cada 14 días")).toEqual({ tipo: "dias", cada: 14 });
  });

  it("la cadencia efectiva cae a diaria cuando no se entiende", () => {
    expect(cadenciaDe(med("cada 36 horas"))).toEqual({ tipo: "dias", cada: 1 });
    expect(cadenciaDe(med("cada 7 días"))).toEqual({ tipo: "dias", cada: 7 });
  });

  it("distingue un campo vacío de una frecuencia ilegible", () => {
    expect(frecuenciaInterpretable(med(""))).toBe(true);
    expect(frecuenciaInterpretable(med("cada 7 días"))).toBe(true);
    expect(frecuenciaInterpretable(med("cada 36 horas"))).toBe(false);
  });
});

describe("días de aplicación", () => {
  const inicio = "2026-01-10";

  it("cuenta desde el inicio del tratamiento", () => {
    const semanal = { tipo: "dias", cada: 7 } as const;
    expect(esDiaDeAplicacion(inicio, "2026-01-10", semanal)).toBe(true);
    expect(esDiaDeAplicacion(inicio, "2026-01-17", semanal)).toBe(true);
    expect(esDiaDeAplicacion(inicio, "2026-01-18", semanal)).toBe(false);
    expect(esDiaDeAplicacion(inicio, "2026-01-09", semanal)).toBe(false);
  });

  it("en cadencia diaria todo día cuenta, salvo los anteriores al inicio", () => {
    const diaria = { tipo: "dias", cada: 1 } as const;
    expect(esDiaDeAplicacion(inicio, "2026-01-10", diaria)).toBe(true);
    expect(esDiaDeAplicacion(inicio, "2026-03-05", diaria)).toBe(true);
    expect(esDiaDeAplicacion(inicio, "2026-01-09", diaria)).toBe(false);
  });

  it("en meses ancla en el día del inicio y tolera los meses cortos", () => {
    const mensual = { tipo: "meses", cada: 1 } as const;
    expect(esDiaDeAplicacion("2026-01-31", "2026-01-31", mensual)).toBe(true);
    expect(esDiaDeAplicacion("2026-01-31", "2026-02-28", mensual)).toBe(true);
    expect(esDiaDeAplicacion("2026-01-31", "2026-03-31", mensual)).toBe(true);
    expect(esDiaDeAplicacion("2026-01-31", "2026-02-27", mensual)).toBe(false);
    expect(esDiaDeAplicacion("2026-01-31", "2026-01-30", mensual)).toBe(false);
  });

  it("restringe el rango pedido", () => {
    const semanal = { tipo: "dias", cada: 7 } as const;
    expect(diasDeAplicacion(inicio, semanal, "2026-01-10", "2026-01-31")).toEqual([
      "2026-01-10",
      "2026-01-17",
      "2026-01-24",
      "2026-01-31",
    ]);
    expect(diasDeAplicacion(inicio, semanal, "2026-02-01", "2026-01-01")).toEqual([]);
  });
});

describe("calendario de aplicaciones", () => {
  it("arma una aplicación por día de toma y horario", () => {
    const tratamiento = tr({
      frecuencia: "cada 7 días",
      horarios: ["09:00"],
      inicio: "2026-01-10",
    });
    const lista = aplicacionesDe(tratamiento, "2026-01-10", "2026-01-31");

    expect(lista.map((aplicacion) => aplicacion.fecha)).toEqual([
      "2026-01-10",
      "2026-01-17",
      "2026-01-24",
      "2026-01-31",
    ]);
    expect(lista[0]?.horario).toBe("09:00");
  });

  it("un medicamento diario con dos horarios da dos aplicaciones por día", () => {
    const tratamiento = tr({
      frecuencia: "cada 12 horas",
      horarios: ["08:00", "20:00"],
      inicio: "2026-01-10",
    });
    const lista = aplicacionesDe(tratamiento, "2026-01-10", "2026-01-11");

    expect(lista).toHaveLength(4);
    expect(lista.map((aplicacion) => `${aplicacion.fecha} ${aplicacion.horario}`)).toEqual([
      "2026-01-10 08:00",
      "2026-01-10 20:00",
      "2026-01-11 08:00",
      "2026-01-11 20:00",
    ]);
  });

  it("sin horario la aplicación existe pero no tiene hora", () => {
    const tratamiento = tr({ frecuencia: "cada 7 días", horarios: [], inicio: "2026-01-10" });
    const lista = aplicacionesDe(tratamiento, "2026-01-10", "2026-01-20");

    expect(lista).toHaveLength(2);
    expect(lista.every((aplicacion) => aplicacion.horario === null)).toBe(true);
  });

  it("usa la misma clave que los recordatorios", () => {
    const tratamiento = tr({ frecuencia: "cada 7 días", horarios: ["09:00"], inicio: "2026-01-10" });
    expect(aplicacionesDe(tratamiento, "2026-01-10", "2026-01-10")[0]?.clave).toBe("2026-01-10|m1|09:00");
  });

  it("respeta la fecha de fin del tratamiento", () => {
    const tratamiento = tr({ frecuencia: "cada 7 días", inicio: "2026-01-10", fin: "2026-01-20" });
    const lista = aplicacionesDe(tratamiento, "2026-01-01", "2026-02-28");

    expect(lista.map((aplicacion) => aplicacion.fecha)).toEqual(["2026-01-10", "2026-01-17"]);
  });

  it("una frecuencia ilegible se comporta como diaria", () => {
    const tratamiento = tr({ frecuencia: "cada 36 horas", inicio: "2026-01-10" });
    const lista = aplicacionesDe(tratamiento, "2026-01-10", "2026-01-12");

    expect(lista.map((aplicacion) => aplicacion.fecha)).toEqual(["2026-01-10", "2026-01-11", "2026-01-12"]);
  });

  it("agrupa los días en orden", () => {
    const tratamiento = tr({
      frecuencia: "cada 12 horas",
      horarios: ["08:00", "20:00"],
      inicio: "2026-01-10",
    });
    const grupos = agruparPorDia(aplicacionesDe(tratamiento, "2026-01-10", "2026-01-11"));

    expect(grupos.map((grupo) => grupo.fecha)).toEqual(["2026-01-10", "2026-01-11"]);
    expect(grupos[0]?.aplicaciones).toHaveLength(2);
  });
});

describe("ventanas de la vista", () => {
  const dia = "2026-10-23";
  // Diario: hace que los límites de la ventana se vean sin trucos.
  const datosEjemplo = datos([tr({ frecuencia: "todos los días", horarios: ["08:00"], inicio: "2026-01-01" })]);

  it("hoy incluye solo hoy", () => {
    const hoy = aplicacionesHoy(datosEjemplo, dia);

    expect(hoy.map((aplicacion) => aplicacion.fecha)).toEqual([dia]);
  });

  it("próximas empieza mañana y llega hasta el tope de la ventana", () => {
    const proximas = aplicacionesProximas(datosEjemplo, dia, 14);

    expect(proximas.every((aplicacion) => aplicacion.fecha > dia)).toBe(true);
    expect(proximas[0]?.fecha).toBe("2026-10-24");
    expect(proximas.at(-1)?.fecha).toBe("2026-11-06");
  });

  it("recientes termina ayer y llega hasta el fondo de la ventana", () => {
    const recientes = aplicacionesRecientes(datosEjemplo, dia, 7);

    expect(recientes.every((aplicacion) => aplicacion.fecha < dia)).toBe(true);
    expect(recientes[0]?.fecha).toBe("2026-10-16");
    expect(recientes.at(-1)?.fecha).toBe("2026-10-22");
  });

  it("un tratamiento que arranca hoy no tiene aplicaciones pasadas", () => {
    const recientes = aplicacionesRecientes(datos([tr({ frecuencia: "cada 7 días", inicio: dia })]), dia, 7);

    expect(recientes).toEqual([]);
  });
});
