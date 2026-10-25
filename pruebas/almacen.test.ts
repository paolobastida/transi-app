import { describe, expect, it } from "vitest";
import { normalizar, serializar } from "../src/almacen";
import { esFechaValida, restarMeses } from "../src/formato";

describe("normalizar respaldos", () => {
  it("acepta un archivo válido y descarta registros incompletos", () => {
    const datos = normalizar({
      version: 4,
      tratamientos: [
        {
          id: "t1",
          medicamentos: [{ id: "m1", nombre: "Testosterona", dosis: "50 mg" }],
          inicio: "2026-01-10",
        },
        { medicamentos: [{ nombre: "" }], inicio: "2026-01-10" },
        { medicamentos: [], inicio: "2026-01-10" },
        { medicamentos: [{ nombre: "Sin fecha" }] },
      ],
      cambios: [
        { id: "c1", fecha: "2026-02-01", descripcion: "Hola" },
        { fecha: "2026-02-01", descripcion: "   " },
      ],
    });

    expect(datos).not.toBeNull();
    expect(datos?.version).toBe(4);
    expect(datos?.tratamientos).toHaveLength(1);
    expect(datos?.cambios).toHaveLength(1);
    expect(datos?.tratamientos[0]?.medicamentos[0]?.nombre).toBe("Testosterona");
    expect(datos?.cambios[0]?.foto).toBeNull();
    expect(datos?.cambios[0]?.audio).toBeNull();
  });

  it("conserva la nota de voz de un cambio", () => {
    const datos = normalizar({
      version: 4,
      tratamientos: [],
      cambios: [
        {
          id: "c1",
          fecha: "2026-02-01",
          descripcion: "Con audio",
          foto: null,
          audio: "data:audio/webm;base64,abc",
        },
      ],
    });

    expect(datos?.cambios[0]?.audio).toBe("data:audio/webm;base64,abc");
  });

  it("migra un tratamiento de la versión anterior (un medicamento suelto)", () => {
    const datos = normalizar({
      version: 2,
      tratamientos: [
        {
          id: "viejo",
          nombre: "Testosterona",
          dosis: "50 mg",
          frecuencia: "cada 7 días",
          inicio: "2026-01-10",
          fin: null,
          profesional: "Dra. Paz",
        },
      ],
      cambios: [],
    });

    expect(datos?.tratamientos[0]?.medicamentos).toHaveLength(1);
    expect(datos?.tratamientos[0]?.medicamentos[0]?.nombre).toBe("Testosterona");
    expect(datos?.tratamientos[0]?.medicamentos[0]?.dosis).toBe("50 mg");
    expect(datos?.tratamientos[0]?.profesional).toBe("Dra. Paz");
  });

  it("rechaza cosas que no son un respaldo", () => {
    expect(normalizar(null)).toBeNull();
    expect(normalizar("texto")).toBeNull();
    expect(normalizar({ tratamientos: [] })).toBeNull();
    expect(normalizar({ tratamientos: [], cambios: {} })).toBeNull();
  });

  it("al importar exige la marca de la app", () => {
    const crudo = { tratamientos: [], cambios: [] };
    // Sin `respaldo` se acepta: los datos de localStorage no traen la marca.
    expect(normalizar(crudo)).not.toBeNull();
    expect(normalizar(crudo, { respaldo: true })).toBeNull();
    expect(normalizar({ app: "transi", ...crudo }, { respaldo: true })).not.toBeNull();
  });

  it("al importar rechaza respaldos de una versión más nueva", () => {
    const crudo = { app: "transi", version: 99, tratamientos: [], cambios: [] };
    expect(normalizar(crudo, { respaldo: true })).toBeNull();
    // Una versión vieja sí entra: se degrada registro a registro.
    expect(normalizar({ ...crudo, version: 2 }, { respaldo: true })).not.toBeNull();
  });

  it("descarta fechas de calendario imposibles", () => {
    const datos = normalizar({
      version: 4,
      tratamientos: [
        { id: "t1", medicamentos: [{ nombre: "Testosterona" }], inicio: "2026-13-45", fin: "prontito" },
        { id: "t2", medicamentos: [{ nombre: "Estradiol" }], inicio: "2026-02-31" },
        { id: "t3", medicamentos: [{ nombre: "Progesterona" }], inicio: "2026-02-28", fin: "2026-02-30" },
      ],
      cambios: [
        { id: "c1", fecha: "2026-02-31", descripcion: "imposible" },
        { id: "c2", fecha: "no-es-fecha", descripcion: "rota" },
        { id: "c3", fecha: "2026-02-28", descripcion: "ok" },
      ],
    });

    // `2026-13-45` y `2026-02-31` no existen: se descartan completos.
    expect(datos?.tratamientos.map((item) => item.id)).toEqual(["t3"]);
    // Un `fin` ilegible no deja el tratamiento "En curso" para siempre.
    expect(datos?.tratamientos[0]?.fin).toBeNull();
    expect(datos?.cambios.map((item) => item.id)).toEqual(["c3"]);
  });

  it("acepta una fecha con hora al final, como las de versiones viejas", () => {
    const datos = normalizar({
      version: 4,
      tratamientos: [],
      cambios: [{ id: "c1", fecha: "2026-02-01T00:00:00.000Z", descripcion: "Con hora" }],
    });
    expect(datos?.cambios[0]?.fecha).toBe("2026-02-01");
  });

  it("serializa con la marca de la app para poder reconocerlo", () => {
    const texto = serializar({ version: 4, tratamientos: [], cambios: [] });
    const leido = JSON.parse(texto);
    expect(leido.app).toBe("transi");
    expect(leido.version).toBe(4);
  });
});

describe("fechas", () => {
  it("resta meses sin desbordar el fin de mes", () => {
    expect(restarMeses("2026-03-31", 1)).toBe("2026-02-28");
    expect(restarMeses("2024-03-31", 1)).toBe("2024-02-29");
    expect(restarMeses("2026-01-15", 1)).toBe("2025-12-15");
  });

  it("esFechaValida distingue formato de calendario real", () => {
    expect(esFechaValida("2026-02-28")).toBe(true);
    expect(esFechaValida("2024-02-29")).toBe(true);
    expect(esFechaValida("2026-02-29")).toBe(false); // 2026 no es bisiesto
    expect(esFechaValida("2026-02-31")).toBe(false);
    expect(esFechaValida("2026-13-01")).toBe(false);
    expect(esFechaValida("2026-00-10")).toBe(false);
    expect(esFechaValida("2026-04-31")).toBe(false);
    expect(esFechaValida("prontito")).toBe(false);
    expect(esFechaValida("")).toBe(false);
    expect(esFechaValida(20260101)).toBe(false);
    expect(esFechaValida(null)).toBe(false);
  });
});
