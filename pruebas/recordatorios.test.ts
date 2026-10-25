import { describe, expect, it } from "vitest";
import { normalizar } from "../src/almacen";
import { crearTratamiento, normalizarHorarios, textoHorarios, type Datos } from "../src/modelo";
import {
  GRACIA_MINUTOS,
  avisosPendientes,
  horaActual,
  recordatoriosDeHoy,
  recordatoriosProgramados,
} from "../src/recordatorios";

/**
 * Tratamiento con horarios dados. El inicio está alineado para que el
 * 23/10/2026 sea día de aplicación de "cada 7 días" (280 días después):
 * los tests de acá prueban *cuándo* suena el aviso, no la cadencia.
 */
function datosCon(horarios: string[], fechas: { inicio?: string; fin?: string | null } = {}): Datos {
  const tratamiento = crearTratamiento({
    medicamentos: [{ nombre: "Testosterona", dosis: "50 mg", frecuencia: "cada 7 días", horarios }],
    inicio: fechas.inicio ?? "2026-01-16",
    fin: fechas.fin ?? null,
    profesional: null,
  });
  return { version: 4, tratamientos: [tratamiento], cambios: [] };
}

/** 23 de octubre de 2026 a las 08:00 hora local. */
const AHORA = new Date(2026, 9, 23, 8, 0);

describe("normalizar horarios", () => {
  it("descarta los inválidos, sin repetir y ordenados", () => {
    expect(normalizarHorarios(["20:00", "08:00", "08:00", "25:00", "7:5", " 12:30 ", "basura"])).toEqual([
      "08:00",
      "12:30",
      "20:00",
    ]);
  });

  it("acepta lista vacía o ausente", () => {
    expect(normalizarHorarios([])).toEqual([]);
    expect(normalizarHorarios(undefined)).toEqual([]);
  });

  it("arma el texto visible", () => {
    expect(textoHorarios([])).toBeNull();
    expect(textoHorarios(["08:00"])).toBe("08:00");
    expect(textoHorarios(["08:00", "20:00"])).toBe("08:00 y 20:00");
    expect(textoHorarios(["07:00", "12:00", "20:00"])).toBe("07:00, 12:00 y 20:00");
  });

  it("al crear un tratamiento guarda solo horarios válidos", () => {
    const tratamiento = crearTratamiento({
      medicamentos: [{ nombre: "X", dosis: "", frecuencia: "", horarios: ["22:00", "99:99", "22:00"] }],
      inicio: "2026-01-01",
      fin: null,
      profesional: null,
    });
    expect(tratamiento.medicamentos[0]?.horarios).toEqual(["22:00"]);
  });
});

describe("avisos pendientes", () => {
  it("avisa en la hora exacta", () => {
    const datos = datosCon(["08:00"]);
    const pendientes = avisosPendientes(datos, AHORA);
    expect(pendientes).toHaveLength(1);
    expect(pendientes[0]?.horario).toBe("08:00");
    expect(pendientes[0]?.medicamento.nombre).toBe("Testosterona");
    expect(pendientes[0]?.clave).toBe(`2026-10-23|${datos.tratamientos[0]?.medicamentos[0]?.id}|08:00`);
  });

  it("no avisa antes de la hora", () => {
    expect(avisosPendientes(datosCon(["08:00"]), new Date(2026, 9, 23, 7, 59))).toHaveLength(0);
  });

  it(`tolera hasta ${GRACIA_MINUTOS} minutos de retraso y no más`, () => {
    const datos = datosCon(["08:00"]);
    expect(avisosPendientes(datos, new Date(2026, 9, 23, 8, GRACIA_MINUTOS))).toHaveLength(1);
    expect(avisosPendientes(datos, new Date(2026, 9, 23, 8, GRACIA_MINUTOS + 1))).toHaveLength(0);
  });

  it("no repite un aviso ya enviado hoy", () => {
    const datos = datosCon(["08:00"]);
    const clave = avisosPendientes(datos, AHORA)[0]?.clave ?? "";
    expect(avisosPendientes(datos, AHORA, new Set([clave]))).toHaveLength(0);
  });

  it("no avisa tratamientos finalizados ni futuros", () => {
    expect(avisosPendientes(datosCon(["08:00"], { fin: "2026-10-01" }), AHORA)).toHaveLength(0);
    expect(avisosPendientes(datosCon(["08:00"], { inicio: "2026-12-01" }), AHORA)).toHaveLength(0);
  });

  it("ignora los medicamentos sin horarios", () => {
    expect(avisosPendientes(datosCon([]), AHORA)).toHaveLength(0);
  });

  it("ordena los avisos de menor a mayor hora", () => {
    const datos = datosCon(["20:00", "08:01", "08:00"]);
    const pendientes = avisosPendientes(datos, new Date(2026, 9, 23, 8, 2));
    expect(pendientes.map((aviso) => aviso.horario)).toEqual(["08:00", "08:01"]);
  });

  it("lee la hora local del sistema", () => {
    expect(horaActual(new Date(2026, 0, 1, 7, 5))).toBe("07:05");
    expect(horaActual(new Date(2026, 0, 1, 23, 9))).toBe("23:09");
  });
});

describe("recordatorios en respaldos", () => {
  it("conserva los horarios válidos y descarta la basura", () => {
    const datos = normalizar({
      version: 4,
      tratamientos: [
        {
          id: "t1",
          medicamentos: [{ id: "m1", nombre: "Testosterona", horarios: ["09:00", "no-es-hora"] }],
          inicio: "2026-01-10",
        },
      ],
      cambios: [],
    });

    expect(datos?.tratamientos[0]?.medicamentos[0]?.horarios).toEqual(["09:00"]);
  });

  it("los respaldos anteriores a los recordatorios quedan sin horarios", () => {
    const datos = normalizar({
      version: 4,
      tratamientos: [{ id: "t1", medicamentos: [{ id: "m1", nombre: "Testosterona" }], inicio: "2026-01-10" }],
      cambios: [],
    });

    expect(datos?.tratamientos[0]?.medicamentos[0]?.horarios).toEqual([]);
  });
});

describe("recordatorios programados", () => {
  function datosConVarios(): Datos {
    const tratamiento = crearTratamiento({
      medicamentos: [
        { nombre: "Testosterona", dosis: "50 mg", frecuencia: "cada 7 días", horarios: ["09:00"] },
        {
          nombre: "Espironolactona",
          dosis: "50 mg",
          frecuencia: "cada 12 horas",
          horarios: ["20:00", "08:00"],
        },
      ],
      inicio: "2026-01-10",
      fin: null,
      profesional: null,
    });
    return { version: 4, tratamientos: [tratamiento], cambios: [] };
  }

  it("programa un aviso por cada medicamento y horario, ordenados por hora", () => {
    const lista = recordatoriosProgramados(datosConVarios(), AHORA);

    expect(lista).toHaveLength(3);
    expect(lista.map((aviso) => `${aviso.hora}:${String(aviso.minuto).padStart(2, "0")}`)).toEqual([
      "8:00",
      "9:00",
      "20:00",
    ]);
    expect(lista[0]).toMatchObject({
      titulo: "Toma de Espironolactona",
      cuerpo: "50 mg · a las 08:00",
      hora: 8,
      minuto: 0,
    });
    expect(lista[1]).toMatchObject({ titulo: "Toma de Testosterona", hora: 9, minuto: 0 });
    expect(lista[2]).toMatchObject({ titulo: "Toma de Espironolactona", hora: 20, minuto: 0 });
  });

  it("usa un id estable que incluye el medicamento y el horario", () => {
    const datos = datosConVarios();
    const medicamento = datos.tratamientos[0]?.medicamentos[1];
    const lista = recordatoriosProgramados(datos, AHORA);

    expect(medicamento).toBeDefined();
    expect(lista[0]?.id).toBe(`transi.recordatorio.${medicamento?.id}.08:00`);
    expect(lista[2]?.id).toBe(`transi.recordatorio.${medicamento?.id}.20:00`);
    // Repetir el cálculo no cambia los ids: reprogramar reemplaza, no duplica.
    expect(recordatoriosProgramados(datos, AHORA).map((aviso) => aviso.id)).toEqual(
      lista.map((aviso) => aviso.id),
    );
  });

  it("no programa tratamientos finalizados ni futuros", () => {
    expect(recordatoriosProgramados(datosCon(["08:00"], { fin: "2026-10-01" }), AHORA)).toEqual([]);
    expect(recordatoriosProgramados(datosCon(["08:00"], { inicio: "2026-12-01" }), AHORA)).toEqual([]);
  });

  it("no programa medicamentos sin horarios", () => {
    expect(recordatoriosProgramados(datosCon([]), AHORA)).toEqual([]);
  });
});

describe("la frecuencia manda sobre los avisos", () => {
  it("no avisa en los días que no corresponden", () => {
    // Inicio 2026-01-10: el 23/10/2026 está a 286 días, no múltiplo de 7.
    expect(avisosPendientes(datosCon(["08:00"], { inicio: "2026-01-10" }), AHORA)).toHaveLength(0);
  });

  it("el día de aplicación se cuenta desde el inicio del tratamiento", () => {
    expect(avisosPendientes(datosCon(["08:00"], { inicio: "2026-10-16" }), AHORA)).toHaveLength(1); // 7 días
    expect(avisosPendientes(datosCon(["08:00"], { inicio: "2026-10-17" }), AHORA)).toHaveLength(0); // 6 días
  });

  it("una frecuencia que no se entiende sigue avisando todos los días", () => {
    const tratamiento = crearTratamiento({
      medicamentos: [{ nombre: "X", dosis: "1 mg", frecuencia: "cada 36 horas", horarios: ["08:00"] }],
      inicio: "2026-01-10",
      fin: null,
      profesional: null,
    });
    const datos: Datos = { version: 4, tratamientos: [tratamiento], cambios: [] };
    expect(avisosPendientes(datos, AHORA)).toHaveLength(1);
  });
});

describe("las fechas que recibe el sistema operativo", () => {
  it("los medicamentos diarios no llevan fechas: el sistema repite solo", () => {
    const tratamiento = crearTratamiento({
      medicamentos: [
        { nombre: "E", dosis: "50 mg", frecuencia: "cada 12 horas", horarios: ["08:00", "20:00"] },
      ],
      inicio: "2026-01-10",
      fin: null,
      profesional: null,
    });
    const lista = recordatoriosProgramados(
      { version: 4, tratamientos: [tratamiento], cambios: [] },
      AHORA,
    );

    expect(lista).toHaveLength(2);
    expect(lista.every((aviso) => aviso.fechas === undefined)).toBe(true);
  });

  it("la frecuencia semanal agenda los días concretos, no todos", () => {
    const lista = recordatoriosProgramados(datosCon(["09:00"]), AHORA);

    expect(lista).toHaveLength(1);
    expect(lista[0]?.fechas?.slice(0, 3)).toEqual(["2026-10-23", "2026-10-30", "2026-11-06"]);
  });

  it("descarta las fechas ya pasadas para que no suenen de inmediato", () => {
    // A las 10:00 la toma de las 09:00 de hoy ya pasó.
    const lista = recordatoriosProgramados(datosCon(["09:00"]), new Date(2026, 9, 23, 10, 0));

    expect(lista[0]?.fechas).not.toContain("2026-10-23");
    expect(lista[0]?.fechas?.[0]).toBe("2026-10-30");
  });

  it("sin tomas pendientes no agenda ni cae al modo diario", () => {
    const lista = recordatoriosProgramados(
      datosCon(["09:00"], { fin: "2026-10-25" }),
      new Date(2026, 9, 23, 10, 0),
    );

    expect(lista).toEqual([]);
  });
});

describe("recordatorios de hoy", () => {
  it("lista los horarios ordenados y marca los ya pasados", () => {
    const datos = datosCon(["20:00", "06:00"]);
    const lista = recordatoriosDeHoy(datos, AHORA);

    expect(lista.map((item) => item.horario)).toEqual(["06:00", "20:00"]);
    expect(lista[0]?.pasado).toBe(true);
    expect(lista[1]?.pasado).toBe(false);
    expect(lista[1]?.nombre).toBe("Testosterona");
    expect(lista[1]?.dosis).toBe("50 mg");
  });

  it("la hora exacta cuenta como pendiente, no como pasada", () => {
    const lista = recordatoriosDeHoy(datosCon(["08:00"]), AHORA);
    expect(lista).toHaveLength(1);
    expect(lista[0]?.pasado).toBe(false);
  });

  it("la clave identifica medicamento y horario", () => {
    const datos = datosCon(["08:00", "20:00"]);
    const lista = recordatoriosDeHoy(datos, AHORA);
    const id = datos.tratamientos[0]?.medicamentos[0]?.id;

    expect(lista[0]?.clave).toBe(`${id}|08:00`);
    expect(lista[1]?.clave).toBe(`${id}|20:00`);
  });

  it("no incluye tratamientos finalizados ni futuros", () => {
    expect(recordatoriosDeHoy(datosCon(["08:00"], { fin: "2026-10-01" }), AHORA)).toEqual([]);
    expect(recordatoriosDeHoy(datosCon(["08:00"], { inicio: "2026-12-01" }), AHORA)).toEqual([]);
  });

  it("queda vacío si ningún medicamento tiene horarios", () => {
    expect(recordatoriosDeHoy(datosCon([]), AHORA)).toEqual([]);
  });

  it("no aparece en días sin toma (frecuencia semanal)", () => {
    // Inicio 2026-01-16: el 23 de octubre es día de toma, el 24 no.
    expect(recordatoriosDeHoy(datosCon(["08:00"]), AHORA)).toHaveLength(1);
    expect(recordatoriosDeHoy(datosCon(["08:00"]), new Date(2026, 9, 24))).toEqual([]);
  });
});
