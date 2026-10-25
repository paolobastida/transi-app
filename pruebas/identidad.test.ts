import { describe, expect, it } from "vitest";
import { perfilDesdeApple } from "../src/apple";
import { decodificarJwt } from "../src/jwt";
import { clavePerfil, iniciales, type Perfil } from "../src/perfil";

const CLIENTE = "com.transi.web";
const SEGUNDO = Math.floor(Date.now() / 1000);

function jwt(payload: Record<string, unknown>): string {
  const base64url = (texto: string): string => {
    const bytes = new TextEncoder().encode(texto);
    let binario = "";
    for (const byte of bytes) binario += String.fromCharCode(byte);
    return btoa(binario).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  };
  return `${base64url('{"alg":"ES256"}')}.${base64url(JSON.stringify(payload))}.firma`;
}

const valido = {
  sub: "001234.abcdef.1234",
  email: "tina@privaterelay.appleid.com",
  aud: CLIENTE,
  iss: "https://appleid.apple.com",
  exp: SEGUNDO + 3600,
};

describe("perfilDesdeApple", () => {
  it("lee la identidad y el nombre que Apple manda una sola vez", () => {
    const perfil = perfilDesdeApple(
      {
        authorization: { id_token: jwt(valido) },
        user: { name: { firstName: "Tina", lastName: "Pérez" } },
      },
      CLIENTE,
      SEGUNDO * 1000,
    );

    expect(perfil).toEqual({
      proveedor: "apple",
      sub: "001234.abcdef.1234",
      nombre: "Tina Pérez",
      email: "tina@privaterelay.appleid.com",
    });
  });

  it("usa el email si Apple no vuelve a mandar el nombre", () => {
    const perfil = perfilDesdeApple(
      { authorization: { id_token: jwt(valido) } },
      CLIENTE,
      SEGUNDO * 1000,
    );
    expect(perfil.nombre).toBe("tina@privaterelay.appleid.com");
  });

  it("rechaza credenciales de otra app, otro emisor o vencidas", () => {
    const respuesta = { authorization: { id_token: jwt(valido) } };
    expect(() => perfilDesdeApple(respuesta, "otro.cliente", SEGUNDO * 1000)).toThrow(
      "no corresponde a esta app",
    );
    expect(() =>
      perfilDesdeApple(
        { authorization: { id_token: jwt({ ...valido, iss: "ejemplo.com" }) } },
        CLIENTE,
        SEGUNDO * 1000,
      ),
    ).toThrow("no vino de Apple");
    expect(() =>
      perfilDesdeApple(
        { authorization: { id_token: jwt({ ...valido, exp: SEGUNDO - 60 }) } },
        CLIENTE,
        SEGUNDO * 1000,
      ),
    ).toThrow("venció");
  });

  it("exige un token y un email", () => {
    expect(() => perfilDesdeApple({}, CLIENTE)).toThrow("credencial");
    expect(() =>
      perfilDesdeApple(
        { authorization: { id_token: jwt({ ...valido, email: undefined }) } },
        CLIENTE,
      ),
    ).toThrow("email");
  });
});

describe("identidad local", () => {
  it("separa los datos por proveedor y sub", () => {
    const perfil: Perfil = {
      proveedor: "facebook",
      sub: "12345",
      nombre: "Tina",
      email: "tina@ejemplo.com",
    };
    expect(clavePerfil(perfil)).toBe("facebook:12345");
  });

  it("arma iniciales con nombre y apellido", () => {
    expect(
      iniciales({ proveedor: "google", sub: "1", nombre: "Tina Pérez", email: "t@e.com" }),
    ).toBe("TP");
    expect(
      iniciales({ proveedor: "google", sub: "1", nombre: "", email: "tina@ejemplo.com" }),
    ).toBe("T");
  });

  it("decodifica un JWT y rechaza texto inválido", () => {
    expect(decodificarJwt(jwt({ hola: "mundo" }))["hola"]).toBe("mundo");
    expect(() => decodificarJwt("no-es-un-jwt")).toThrow("formato");
  });
});
