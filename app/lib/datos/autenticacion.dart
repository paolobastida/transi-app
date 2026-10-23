import '../dominio/sesion.dart';
import '../dominio/usuario.dart';
import 'almacen_sesion.dart';
import 'api_client.dart';
import 'base_local.dart';

/// Casos de uso de identidad del lado de la app (U1–U3).
class Autenticacion {
  final ApiClient _api;
  final AlmacenSesion _almacen;
  final BaseLocal? _base;

  Autenticacion({
    ApiClient? api,
    AlmacenSesion? almacen,
    this._base,
  })  : _api = api ?? ApiClient(),
        _almacen = almacen ?? AlmacenSesion();

  /// Borra todos los datos locales de salud de un usuario.
  ///
  /// Sin esto, cerrar sesión dejaba tratamientos, cambios, fotos y notas de voz
  /// en la base: el siguiente usuario del mismo dispositivo los tenía en su
  /// base (aunque la interfaz los filtrara bien). Es lo que hacía posible que
  /// el respaldo de una cuenta incluyera los datos de otra.
  Future<void> purgarDatosLocales() async {
    final base = _base;
    if (base == null) return;
    await base.transaction(() async {
      await base.delete(base.adjuntos).go();
      await base.delete(base.cambios).go();
      await base.delete(base.tratamientos).go();
    });
  }

  /// U1 · Crear cuenta.
  Future<void> registrar(String email, String clave) async {
    await _api.postPublico('/auth/registro', {'email': email, 'clave': clave});
  }

  /// U2 · Iniciar sesión. Requiere red (primera vez).
  Future<Usuario> entrar(String email, String clave) async {
    final datos = await _api.postPublico(
      '/auth/login',
      {'email': email, 'clave': clave},
    );
    await _almacen.guardar(Sesion.fromJson(datos));

    final usuario = await _quienSoy();
    await _almacen.guardarUsuario(usuario);
    return usuario;
  }

  Future<Usuario> _quienSoy() async {
    final datos = await _api.getAutenticado('/auth/yo');
    return Usuario.fromJson(datos);
  }

  /// Devuelve el usuario guardado, **sin usar red**. Es lo que permite arrancar
  /// la app en modo avión una vez que ya se inició sesión.
  Future<Usuario?> sesionActual() async {
    final sesion = await _almacen.leer();
    if (sesion == null) return null;
    return _almacen.leerUsuario();
  }

  /// Cerrar sesión: revoca el refresh en el servidor (si hay red), **borra los
  /// datos locales de salud** y limpia la sesión guardada.
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
    // Los datos quedan en el respaldo del servidor, que es donde deben estar.
    await purgarDatosLocales();
  }
}
