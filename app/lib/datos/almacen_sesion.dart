import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../dominio/sesion.dart';

/// Guarda la sesión (tokens) en el almacenamiento seguro del dispositivo.
/// Los tokens son sensibles: no se guardan en texto plano de preferencias.
class AlmacenSesion {
  static const _clave = 'sesion';

  final FlutterSecureStorage _almacen;

  AlmacenSesion([FlutterSecureStorage? almacen])
      : _almacen = almacen ?? const FlutterSecureStorage();

  Future<void> guardar(Sesion sesion) =>
      _almacen.write(key: _clave, value: jsonEncode(sesion.toJson()));

  Future<Sesion?> leer() async {
    final valor = await _almacen.read(key: _clave);
    if (valor == null) return null;
    return Sesion.fromJson(jsonDecode(valor) as Map<String, dynamic>);
  }

  Future<void> borrar() => _almacen.delete(key: _clave);
}
