import { describe, expect, it } from "vitest";
import {
  agruparPorMes,
  crearCambio,
  crearTratamiento,
  datosDemo,
  guardarEnLista,
  lineaDeTiempo,
  resumenTratamiento,
  tituloTratamiento,
  tratamientoActivo,
  tratamientosEnCurso,
  validarCambio,
  validarTratamiento,
  type EntradaTratamiento,
} from "../src/modelo";

const base: EntradaTratamiento = {
  medicamentos: [{ nombre: "  Testosterona ", dosis: "50 mg", frecuencia: "cada 7 días" }],
  inicio: "2026-01-10",
  fin: null,
  profesional: "  ",
};

const dosMedicamentos: EntradaTratamiento = {
  ...base,
  medicamentos: [
    { nombre: "Testosterona", dosis: "50 mg", frecuencia: "cada 7 días" },
    { nombre: "Espironolactona", dosis: "50 mg", frecuencia: "cada 12 horas" },
  ],
};

describe("tratamientos", () => {
  it("limpia los espacios y guarda el profesional vacío como null", () => {
    const tratamiento = crearTratamiento(base);
    expect(tratamiento.medicamentos[0]?.nombre).toBe("Testosterona");
    expect(tratamiento.profesional).toBeNull();
    expect(tratamiento.fin).toBeNull();
  });

  it("permite varios medicamentos con ids distintos", () => {
    const tratamiento = crearTratamiento(dosMedicamentos);
    expect(tratamiento.medicamentos).toHaveLength(2);
    expect(tratamiento.medicamentos[0]?.id).not.toBe(tratamiento.medicamentos[1]?.id);
    expect(tratamiento.medicamentos[1]?.nombre).toBe("Espironolactona");
  });

  it("exige al menos un medicamento y un nombre en cada uno", () => {
    expect(validarTratamiento({ ...base, medicamentos: [] })).toMatch(/al menos un medicamento/i);
    expect(
      validarTratamiento({ ...dosMedicamentos, medicamentos: [{ nombre: " ", dosis: "", frecuencia: "" }] }),
    ).toMatch(/nombre/i);
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

  it("arma un título legible según la cantidad de medicamentos", () => {
    expect(tituloTratamiento(crearTratamiento(base))).toBe("Testosterona");
    expect(tituloTratamiento(crearTratamiento(dosMedicamentos))).toBe("Testosterona + Espironolactona");

    const tres = crearTratamiento({
      ...base,
      medicamentos: [...dosMedicamentos.medicamentos, { nombre: "Progesterona", dosis: "", frecuencia: "" }],
    });
    expect(tituloTratamiento(tres)).toBe("Testosterona + 2 más");
  });

  it("resume dosis y frecuencia cuando hay un solo medicamento", () => {
    expect(resumenTratamiento(crearTratamiento(base))).toBe("50 mg · cada 7 días");
    expect(resumenTratamiento(crearTratamiento(dosMedicamentos))).toBe("2 medicamentos");
    expect(
      resumenTratamiento(
        crearTratamiento({ ...base, medicamentos: [{ nombre: "Testosterona", dosis: "", frecuencia: "" }] }),
      ),
    ).toBe("Tratamiento");
  });

  it("agrega un tratamiento nuevo o reemplaza el existente", () => {
    const uno = crearTratamiento(base);
    expect(guardarEnLista([], uno)).toHaveLength(1);
    const editado = { ...uno, medicamentos: crearTratamiento(dosMedicamentos).medicamentos };
    const lista = guardarEnLista([uno], editado);
    expect(lista).toHaveLength(1);
    expect(lista[0]?.medicamentos).toHaveLength(2);
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

  it("los datos de ejemplo incluyen un tratamiento con varios medicamentos", () => {
    expect(datos.tratamientos.some((tratamiento) => tratamiento.medicamentos.length > 1)).toBe(true);
  });
});
