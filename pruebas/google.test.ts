import { describe, expect, it } from "vitest";
import { perfilDesdeCredencial } from "../src/google";

const CLIENTE = "42.apps.googleusercontent.com";
const SEGUNDO = Math.floor(Date.now() / 1000);

/** Arma un JWT con el payload dado. La firma la garantiza Google en el
 *  navegador real; acá solo importa el payload, que es lo que decodificamos.
 *  Usa TextEncoder + btoa (disponibles en Node y en el navegador) en vez de
 *  Buffer, porque el proyecto no tiene @types/node. */
function credencial(payload: Record<string, unknown>): string {
  const base64url = (texto: string): string => {
    const bytes = new TextEncoder().encode(texto);
    let binario = "";
    for (const byte of bytes) binario += String.fromCharCode(byte);
    return btoa(binario).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  };
  return `${base64url('{"alg":"RS256","typ":"JWT"}')}.${base64url(JSON.stringify(payload))}.firma`;
}

const valido = {
  sub: "118765432109876543210",
  email: "tina@gmail.com",
  name: "Tina Pérez",
  aud: CLIENTE,
  iss: "accounts.google.com",
  exp: SEGUNDO + 3600,
};

describe("perfilDesdeCredencial", () => {
  it("lee sub, nombre y email de una credencial válida", () => {
    const perfil = perfilDesdeCredencial(credencial(valido), CLIENTE, SEGUNDO * 1000);
    expect(perfil).toEqual({
      proveedor: "google",
      sub: "118765432109876543210",
      nombre: "Tina Pérez",
      email: "tina@gmail.com",
    });
  });

  it("acepta el issuer con https", () => {
    const perfil = perfilDesdeCredencial(
      credencial({ ...valido, iss: "https://accounts.google.com" }),
      CLIENTE,
      SEGUNDO * 1000,
    );
    expect(perfil.email).toBe("tina@gmail.com");
  });

  it("cae a given_name si no hay nombre completo", () => {
    const perfil = perfilDesdeCredencial(
      credencial({ ...valido, name: undefined, given_name: "Tina" }),
      CLIENTE,
      SEGUNDO * 1000,
    );
    expect(perfil.nombre).toBe("Tina");
  });

  it("cae al email si no trae ningún nombre", () => {
    const perfil = perfilDesdeCredencial(
      credencial({ ...valido, name: undefined, given_name: undefined }),
      CLIENTE,
      SEGUNDO * 1000,
    );
    expect(perfil.nombre).toBe("tina@gmail.com");
  });

  it("rechaza una credencial emitida para OTRA app (aud)", () => {
    // Sin esto, una credencial válida de otra app mía podría abrir sesión acá.
    expect(() => perfilDesdeCredencial(credencial(valido), "otro.cliente", SEGUNDO * 1000)).toThrow(
      "no corresponde a esta app",
    );
  });

  it("rechaza una respuesta que no vino de Google (iss)", () => {
    expect(() =>
      perfilDesdeCredencial(credencial({ ...valido, iss: "ejemplo.com" }), CLIENTE, SEGUNDO * 1000),
    ).toThrow("no vino de Google");
  });

  it("rechaza una credencial vencida (exp)", () => {
    expect(() =>
      perfilDesdeCredencial(
        credencial({ ...valido, exp: SEGUNDO - 60 }),
        CLIENTE,
        SEGUNDO * 1000,
      ),
    ).toThrow("venció");
  });

  it("rechaza una credencial sin sub o sin email", () => {
    expect(() => perfilDesdeCredencial(credencial({ ...valido, sub: undefined }), CLIENTE)).toThrow(
      "identificador",
    );
    expect(() => perfilDesdeCredencial(credencial({ ...valido, email: undefined }), CLIENTE)).toThrow(
      "email",
    );
  });

  it("rechaza un texto que ni siquiera parece un JWT", () => {
    // Acá lo que importa es que se rechace, no el texto exacto: el mensaje
    // es de UI y puede cambiar. Los que sí fijamos abajo son los de seguridad.
    expect(() => perfilDesdeCredencial("no-es-una-credencial", CLIENTE)).toThrow();
    expect(() => perfilDesdeCredencial("a.b.c", CLIENTE)).toThrow();
  });

  it("sin client id configurado no valida el aud (así se prueba en local)", () => {
    const perfil = perfilDesdeCredencial(credencial(valido), "", SEGUNDO * 1000);
    expect(perfil.sub).toBe("118765432109876543210");
  });
});
