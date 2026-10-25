import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  actualizar,
  borrarRespaldoRoto,
  borrarTodo,
  cargar,
  guardar,
  invalidarMemoria,
  respaldoRoto,
} from "../src/almacen";
import { datosVacios, type Cambio, type Datos } from "../src/modelo";

/** localStorage en memoria: vitest corre en node y no trae uno. */
class AlmacenFalso {
  private mapa = new Map<string, string>();

  getItem(clave: string): string | null {
    return this.mapa.get(clave) ?? null;
  }

  setItem(clave: string, valor: string): void {
    this.mapa.set(clave, String(valor));
  }

  removeItem(clave: string): void {
    this.mapa.delete(clave);
  }

  clear(): void {
    this.mapa.clear();
  }

  key(indice: number): string | null {
    return [...this.mapa.keys()][indice] ?? null;
  }

  get length(): number {
    return this.mapa.size;
  }
}

const cambio = (id: string): Cambio => ({
  id,
  fecha: "2026-01-15",
  descripcion: `registro ${id}`,
  foto: null,
  audio: null,
});

const conCambios = (...ids: string[]): Datos => ({
  version: 4,
  tratamientos: [],
  cambios: ids.map(cambio),
});

beforeEach(() => {
  vi.stubGlobal("localStorage", new AlmacenFalso());
  invalidarMemoria();
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("escrituras compartidas", () => {
  it("muta sobre los datos frescos, no sobre la copia que la vista guardó al montarse", () => {
    // La vista captura los datos al montarse.
    const vistoEnLaVista = cargar();
    expect(vistoEnLaVista.cambios).toHaveLength(0);

    // Otra pestaña guarda mientras tanto.
    expect(guardar(conCambios("otra-pestaña"))).toBe(true);

    // Esta pestaña muta y guarda: lo de la otra pestaña no puede perderse.
    expect(actualizar((actuales) => ({ ...actuales, cambios: [...actuales.cambios, cambio("esta-pestaña")] }))).toBe(
      true,
    );

    const guardado = JSON.parse(localStorage.getItem("transi.datos") ?? "{}") as Datos;
    expect(guardado.cambios.map((item) => item.id)).toEqual(["otra-pestaña", "esta-pestaña"]);
  });

  it("invalidarMemoria obliga a releer de localStorage", () => {
    expect(cargar()).toEqual(datosVacios());
    localStorage.setItem("transi.datos", JSON.stringify(conCambios("nuevo")));

    // Sin invalidar, la caché seguía devolviendo vacío.
    expect(cargar()).toEqual(datosVacios());
    invalidarMemoria();
    expect(cargar().cambios).toHaveLength(1);
  });
});

describe("respaldo ilegible", () => {
  it("aparta una copia en vez de devolver vacío sin avisar", () => {
    localStorage.setItem("transi.datos", "{esto no es json");

    expect(cargar()).toEqual(datosVacios());
    expect(respaldoRoto()).toBe("{esto no es json");
  });

  it("no pisa la copia apartada cuando vuelve a haber datos", () => {
    localStorage.setItem("transi.datos", "{roto");

    expect(cargar()).toEqual(datosVacios());
    expect(guardar(conCambios("despues"))).toBe(true);

    // El registro nuevo vive en la clave normal; la copia rota sigue intacta.
    expect(cargar().cambios).toHaveLength(1);
    expect(respaldoRoto()).toBe("{roto");
  });

  it("descarta la copia apartada solo cuando se pide", () => {
    localStorage.setItem("transi.datos", "{roto");
    cargar();
    expect(respaldoRoto()).toBe("{roto");
    expect(borrarRespaldoRoto()).toBe(true);
    expect(respaldoRoto()).toBeNull();
  });

  it("borrarTodo no deja ni la copia dañada", () => {
    localStorage.setItem("transi.datos", "{roto");
    cargar();
    expect(borrarTodo()).toBe(true);
    expect(respaldoRoto()).toBeNull();
    expect(cargar()).toEqual(datosVacios());
  });
});
