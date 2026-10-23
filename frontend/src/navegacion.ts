import { estado } from "./estado";
import type { Cambio, Tratamiento, Usuario } from "./tipos";
import { montar } from "./ui";
import { vistaCuenta } from "./vistas/cuenta";
import { vistaDetalleCambio } from "./vistas/detalle_cambio";
import { vistaFormularioCambio } from "./vistas/formulario_cambio";
import { vistaFormularioTratamiento } from "./vistas/formulario_tratamiento";
import { vistaInicio } from "./vistas/inicio";
import { vistaLogin } from "./vistas/login";
import { vistaRegistro } from "./vistas/registro";

export function irALogin(): void {
  estado.usuario = null;
  montar(vistaLogin());
}

export function irARegistro(): void {
  montar(vistaRegistro());
}

export function irAInicio(usuario: Usuario, pestana = 0): void {
  estado.usuario = usuario;
  montar(vistaInicio(usuario, pestana));
}

export function irATratamiento(usuario: Usuario, tratamiento?: Tratamiento): void {
  montar(vistaFormularioTratamiento(usuario, tratamiento));
}

export function irACambio(usuario: Usuario): void {
  montar(vistaFormularioCambio(usuario));
}

export function irADetalleCambio(usuario: Usuario, cambio: Cambio): void {
  montar(vistaDetalleCambio(usuario, cambio));
}

export function irACuenta(usuario: Usuario): void {
  montar(vistaCuenta(usuario));
}
