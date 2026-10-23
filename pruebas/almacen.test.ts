import { describe, expect, it } from "vitest";
import { normalizar, serializar } from "../src/almacen";
import { restarMeses } from "../src/formato";

describe("normalizar respaldos", () => {
  it("acepta un archivo válido y descarta registros incompletos", () => {
    const datos = normalizar({
      version: 2,
      tratamientos: [
        { id: "t1", nombre: "Testosterona", inicio: "2026-01-10" },
        { nombre: "", inicio: "2026-01-10" },
        { nombre: "Sin fecha" },
      ],
      cambios: [
        { id: "c1", fecha: "2026-02-01", descripcion: "Hola" },
        { fecha: "2026-02-01", descripcion: "   " },
      ],
    });

    expect(datos).not.toBeNull();
    expect(datos?.version).toBe(2);
    expect(datos?.tratamientos).toHaveLength(1);
    expect(datos?.cambios).toHaveLength(1);
    expect(datos?.tratamientos[0]?.nombre).toBe("Testosterona");
    expect(datos?.cambios[0]?.foto).toBeNull();
  });

  it("rechaza cosas que no son un respaldo", () => {
    expect(normalizar(null)).toBeNull();
    expect(normalizar("texto")).toBeNull();
    expect(normalizar({ tratamientos: [] })).toBeNull();
    expect(normalizar({ tratamientos: [], cambios: {} })).toBeNull();
  });

  it("serializa con la marca de la app para poder reconocerlo", () => {
    const texto = serializar({ version: 2, tratamientos: [], cambios: [] });
    const leido = JSON.parse(texto);
    expect(leido.app).toBe("transi");
    expect(leido.version).toBe(2);
  });
});

describe("fechas", () => {
  it("resta meses sin desbordar el fin de mes", () => {
    expect(restarMeses("2026-03-31", 1)).toBe("2026-02-28");
    expect(restarMeses("2024-03-31", 1)).toBe("2024-02-29");
    expect(restarMeses("2026-01-15", 1)).toBe("2025-12-15");
  });
});
