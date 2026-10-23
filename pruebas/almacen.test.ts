import { describe, expect, it } from "vitest";
import { normalizar, serializar } from "../src/almacen";
import { restarMeses } from "../src/formato";

describe("normalizar respaldos", () => {
  it("acepta un archivo válido y descarta registros incompletos", () => {
    const datos = normalizar({
      version: 3,
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
    expect(datos?.version).toBe(3);
    expect(datos?.tratamientos).toHaveLength(1);
    expect(datos?.cambios).toHaveLength(1);
    expect(datos?.tratamientos[0]?.medicamentos[0]?.nombre).toBe("Testosterona");
    expect(datos?.cambios[0]?.foto).toBeNull();
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

  it("serializa con la marca de la app para poder reconocerlo", () => {
    const texto = serializar({ version: 3, tratamientos: [], cambios: [] });
    const leido = JSON.parse(texto);
    expect(leido.app).toBe("transi");
    expect(leido.version).toBe(3);
  });
});

describe("fechas", () => {
  it("resta meses sin desbordar el fin de mes", () => {
    expect(restarMeses("2026-03-31", 1)).toBe("2026-02-28");
    expect(restarMeses("2024-03-31", 1)).toBe("2024-02-29");
    expect(restarMeses("2026-01-15", 1)).toBe("2025-12-15");
  });
});
