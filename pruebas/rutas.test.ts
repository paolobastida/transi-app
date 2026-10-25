import { describe, expect, it } from "vitest";
import { analizarRuta } from "../src/rutas";

describe("rutas", () => {
  it("reconoce la portada y las pantallas simples", () => {
    expect(analizarRuta("/")).toEqual({ nombre: "inicio" });
    expect(analizarRuta("")).toEqual({ nombre: "inicio" });
    expect(analizarRuta("/registrar")).toEqual({ nombre: "registrar" });
    expect(analizarRuta("/ajustes")).toEqual({ nombre: "ajustes" });
    expect(analizarRuta("/entrar")).toEqual({ nombre: "entrada" });
    expect(analizarRuta("/ayuda")).toEqual({ nombre: "ayuda" });
  });

  it("distingue crear de editar", () => {
    expect(analizarRuta("/tratamiento")).toEqual({ nombre: "tratamiento", id: undefined });
    expect(analizarRuta("/tratamiento/abc")).toEqual({ nombre: "tratamiento", id: "abc" });
    expect(analizarRuta("/cambio/xyz")).toEqual({ nombre: "cambio", id: "xyz" });
  });

  it("lee el detalle con su tipo y su id", () => {
    expect(analizarRuta("/detalle/tratamiento/123")).toEqual({
      nombre: "detalle",
      tipo: "tratamiento",
      id: "123",
    });
    expect(analizarRuta("/detalle/cambio/456")).toEqual({
      nombre: "detalle",
      tipo: "cambio",
      id: "456",
    });
  });

  it("marca como desconocida cualquier otra ruta", () => {
    expect(analizarRuta("/detalle").nombre).toBe("desconocida");
    expect(analizarRuta("/detalle/profesional/1").nombre).toBe("desconocida");
    expect(analizarRuta("/loquesea").nombre).toBe("desconocida");
  });
});
