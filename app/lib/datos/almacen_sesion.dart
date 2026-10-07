import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../dominio/sesion.dart';
import '../dominio/usuario.dart';

/// Guarda la sesión (tokens) y los datos de la cuenta en el almacenamiento
/// seguro del dispositivo.
///
/// Guardamos también el usuario para poder **arrancar sin internet**: si hay
/// sesión guardada, la app entra directo sin preguntar al servidor (offline-first).
class AlmacenSesion {
  static const _claveSesion = 'sesion';
  static const _claveUsuario = 'usuario';

  final FlutterSecureStorage _almacen;

  AlmacenSesion([FlutterSecureStorage? almacen])
      : _almacen = almacen ?? const FlutterSecureStorage();

  Future<void> guardar(Sesion sesion) =>
      _almacen.write(key: _claveSesion, value: jsonEncode(sesion.toJson()));

  Future<Sesion?> leer() async {
    final valor = await _almacen.read(key: _claveSesion);
    if (valor == null) return null;
    return Sesion.fromJson(jsonDecode(valor) as Map<String, dynamic>);
  }

  Future<void> guardarUsuario(Usuario usuario) => _almacen.write(
        key: _claveUsuario,
        value: jsonEncode({'id': usuario.id, 'email': usuario.email}),
      );

  Future<Usuario?> leerUsuario() async {
    final valor = await _almacen.read(key: _claveUsuario);
    if (valor == null) return null;
    return Usuario.fromJson(jsonDecode(valor) as Map<String, dynamic>);
  }

  Future<void> borrar() async {
    await _almacen.delete(key: _claveSesion);
    await _almacen.delete(key: _claveUsuario);
  }
}
