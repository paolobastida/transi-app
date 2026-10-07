import '../dominio/sesion.dart';
import '../dominio/usuario.dart';
import 'almacen_sesion.dart';
import 'api_client.dart';

/// Casos de uso de identidad del lado de la app (U1–U3).
class Autenticacion {
  final ApiClient _api;
  final AlmacenSesion _almacen;

  Autenticacion({ApiClient? api, AlmacenSesion? almacen})
      : _api = api ?? ApiClient(),
        _almacen = almacen ?? AlmacenSesion();

  /// U1 · Crear cuenta.
  Future<void> registrar(String email, String clave) async {
    await _api.postPublico('/auth/registro', {'email': email, 'clave': clave});
  }

  /// U2 · Iniciar sesión y guardar los tokens.
  Future<Usuario> entrar(String email, String clave) async {
    final datos = await _api.postPublico(
      '/auth/login',
      {'email': email, 'clave': clave},
    );
    await _almacen.guardar(Sesion.fromJson(datos));
    return _quienSoy();
  }

  /// U3 · Obtener quién soy (usa el token guardado).
  Future<Usuario> _quienSoy() async {
    final datos = await _api.getAutenticado('/auth/yo');
    return Usuario.fromJson(datos);
  }

  /// Devuelve el usuario si hay una sesión válida; si no, null.
  Future<Usuario?> sesionActual() async {
    if (await _almacen.leer() == null) return null;
    try {
      return await _quienSoy();
    } catch (_) {
      return null;
    }
  }

  /// Cerrar sesión: revoca el refresh en el servidor y borra los tokens.
  Future<void> salir() async {
    final sesion = await _almacen.leer();
    if (sesion != null) {
      try {
        await _api.postPublico('/auth/logout', {'refresco': sesion.refresco});
      } catch (_) {
        // Aunque falle el servidor, igual borramos la sesión local.
      }
    }
    await _almacen.borrar();
  }
}
