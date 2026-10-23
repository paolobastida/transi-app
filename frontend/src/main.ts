import { api } from "./api";
import { irAInicio, irALogin } from "./navegacion";
import { cargando, montar } from "./ui";

async function arrancar(): Promise<void> {
  montar(cargando());
  try {
    const usuario = await api.sesionActual();
    if (usuario) {
      irAInicio(usuario);
    } else {
      irALogin();
    }
  } catch {
    // Sin sesión (o backend no disponible): se pide entrar.
    irALogin();
  }
}

void arrancar();
