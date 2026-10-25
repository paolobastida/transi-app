import { describe, expect, it } from "vitest";
import { camaraDisponible, Camara, mensajeCamara } from "../src/camara";

/** Reproduce el error que lanza el navegador cuando se niega el permiso. */
function errorDe(nombre: string): DOMException {
  return new DOMException("fallo", nombre);
}

describe("cámara", () => {
  it("no dice que hay cámara disponible donde no hay mediaDevices", () => {
    expect(camaraDisponible()).toBe(false);
  });

  it("explica que falta el permiso cuando el navegador lo niega", () => {
    expect(mensajeCamara(errorDe("NotAllowedError"))).toContain("permiso");
    expect(mensajeCamara(errorDe("SecurityError"))).toContain("permiso");
  });

  it("explica que no hay cámara cuando no existe un dispositivo de video", () => {
    expect(mensajeCamara(errorDe("NotFoundError"))).toContain("cámara disponible");
    expect(mensajeCamara(errorDe("OverconstrainedError"))).toContain("cámara disponible");
  });

  it("explica que otra aplicación está usando la cámara", () => {
    expect(mensajeCamara(errorDe("NotReadableError"))).toContain("otra aplicación");
  });

  it("deja pasar el mensaje original si no reconoce el error", () => {
    expect(mensajeCamara(new Error("algo raro"))).toBe("algo raro");
    expect(mensajeCamara("texto")).toBe("No pudimos acceder a la cámara.");
  });

  it("arranca apagada y cerrar dos veces no rompe nada", () => {
    const camara = new Camara();
    expect(camara.activa).toBe(false);
    camara.cerrar();
    camara.cerrar();
    expect(camara.activa).toBe(false);
  });

  it("al pedir una foto con la cámara cerrada da un error claro", async () => {
    const camara = new Camara();
    // `tomarFoto` es async (canvas.toBlob), así que rechaza en vez de lanzar.
    await expect(camara.tomarFoto({} as HTMLVideoElement)).rejects.toThrow(
      "La cámara no está abierta.",
    );
  });
});
