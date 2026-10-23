import { describe, expect, it } from "vitest";
import { audioDisponible, segundosATexto } from "../src/grabadora";

describe("grabadora", () => {
  it("formatea los segundos como minutos:segundos", () => {
    expect(segundosATexto(0)).toBe("0:00");
    expect(segundosATexto(7)).toBe("0:07");
    expect(segundosATexto(60)).toBe("1:00");
  });

  it("no dice que hay audio disponible donde no hay micrófono", () => {
    expect(audioDisponible()).toBe(false);
  });
});
