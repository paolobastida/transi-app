import { describe, expect, it } from "vitest";
import { emailValido, perfilDesdeEmail } from "../src/acceso_email";
import { clavePerfil } from "../src/perfil";

describe("acceso con email", () => {
  it("normaliza el email y conserva el nombre", () => {
    expect(perfilDesdeEmail("  Tina@Ejemplo.COM ", " Tina Pérez ")).toEqual({
      proveedor: "email",
      sub: "tina@ejemplo.com",
      nombre: "Tina Pérez",
      email: "tina@ejemplo.com",
    });
  });

  it("usa la parte local del email si no hay nombre", () => {
    expect(perfilDesdeEmail("tina@ejemplo.com")?.nombre).toBe("tina");
  });

  it("rechaza emails inválidos", () => {
    expect(emailValido("tina@ejemplo.com")).toBe(true);
    expect(emailValido("tina")).toBe(false);
    expect(emailValido("tina@")).toBe(false);
    expect(perfilDesdeEmail("tina@")).toBeNull();
  });

  it("separa los datos con una clave estable por email", () => {
    const perfil = perfilDesdeEmail("Tina@Ejemplo.com");
    expect(perfil && clavePerfil(perfil)).toBe("email:tina@ejemplo.com");
  });
});
