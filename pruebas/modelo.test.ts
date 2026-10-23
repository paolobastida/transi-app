import { describe, expect, it } from "vitest";
import {
  agruparPorMes,
  crearCambio,
  crearTratamiento,
  datosDemo,
  guardarEnLista,
  lineaDeTiempo,
  resumenTratamiento,
  tratamientoActivo,
  tratamientosEnCurso,
  validarCambio,
  validarTratamiento,
} from "../src/modelo";

const base = {
  nombre: "  Testosterona ",
  dosis: "50 mg",
  frecuencia: "cada 7 días",
  inicio: "2026-01-10",
  fin: null,
  profesional: "  ",
};

describe("tratamientos", () => {
  it("limpia los espacios y guarda el profesional vacío como null", () => {
    const tratamiento = crearTratamiento(base);
    expect(tratamiento.nombre).toBe("Testosterona");
    expect(tratamiento.profesional).toBeNull();
    expect(tratamiento.fin).toBeNull();
  });

  it("exige nombre y fecha de inicio", () => {
    expect(validarTratamiento({ ...base, nombre: "  " })).toMatch(/medicamento/i);
    expect(validarTratamiento({ ...base, inicio: "" })).toMatch(/inicio/i);
  });

  it("no acepta un fin anterior al inicio", () => {
    expect(validarTratamiento({ ...base, fin: "2025-12-31" })).toMatch(/anterior/i);
    expect(validarTratamiento({ ...base, fin: "2026-02-01" })).toBeNull();
  });

  it("deriva si está activo a partir de la fecha de fin", () => {
    const tratamiento = crearTratamiento(base);
    expect(tratamientoActivo(tratamiento, "2030-01-01")).toBe(true);

    const cerrado = { ...tratamiento, fin: "2026-03-01" };
    expect(tratamientoActivo(cerrado, "2026-02-28")).toBe(true);
    expect(tratamientoActivo(cerrado, "2026-03-02")).toBe(false);
  });

  it("resume dosis y frecuencia sin dejar separadores sueltos", () => {
    expect(resumenTratamiento(crearTratamiento(base))).toBe("50 mg · cada 7 días");
    expect(resumenTratamiento(crearTratamiento({ ...base, dosis: "", frecuencia: "" }))).toBe("");
  });

  it("agrega un tratamiento nuevo o reemplaza el existente", () => {
    const uno = crearTratamiento(base);
    expect(guardarEnLista([], uno)).toHaveLength(1);
    const editado = { ...uno, dosis: "100 mg" };
    const lista = guardarEnLista([uno], editado);
    expect(lista).toHaveLength(1);
    expect(lista[0]?.dosis).toBe("100 mg");
  });
});

describe("cambios", () => {
  it("exige descripción y fecha", () => {
    expect(validarCambio({ fecha: "2026-01-01", descripcion: " ", foto: null })).toMatch(/cambió/i);
    expect(validarCambio({ fecha: "", descripcion: "algo", foto: null })).toMatch(/fecha/i);
  });

  it("guarda la foto opcional", () => {
    const cambio = crearCambio({ fecha: "2026-01-01", descripcion: "  hola  ", foto: "data:image/jpeg;base64,x" });
    expect(cambio.descripcion).toBe("hola");
    expect(cambio.foto).toContain("data:image");
  });
});

describe("línea de tiempo", () => {
  const datos = datosDemo("2026-10-22");

  it("ordena de lo más reciente a lo más viejo", () => {
    const fechas = lineaDeTiempo(datos).map((evento) => evento.fecha);
    expect(fechas).toEqual([...fechas].sort().reverse());
  });

  it("filtra por tipo", () => {
    const soloCambios = lineaDeTiempo(datos, "cambios");
    expect(soloCambios.every((evento) => evento.tipo === "cambio")).toBe(true);
    expect(soloCambios).toHaveLength(datos.cambios.length);

    const soloTratamientos = lineaDeTiempo(datos, "tratamientos");
    expect(soloTratamientos.every((evento) => evento.tipo === "tratamiento")).toBe(true);
  });

  it("agrupa por mes respetando el orden", () => {
    const grupos = agruparPorMes(lineaDeTiempo(datos));
    const meses = grupos.map((grupo) => grupo.mes);
    expect(new Set(meses).size).toBe(meses.length);
    expect(grupos.reduce((total, grupo) => total + grupo.eventos.length, 0)).toBe(
      datos.cambios.length + datos.tratamientos.length,
    );
  });

  it("deja solo los tratamientos en curso, del más reciente al más viejo", () => {
    const enCurso = tratamientosEnCurso(datos, "2026-10-22");
    expect(enCurso.every((tratamiento) => tratamientoActivo(tratamiento, "2026-10-22"))).toBe(true);
    const inicios = enCurso.map((tratamiento) => tratamiento.inicio);
    expect(inicios).toEqual([...inicios].sort().reverse());
  });
});
