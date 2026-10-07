import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../dominio/sesion.dart';
import 'almacen_sesion.dart';

/// Error devuelto por la API, con el mensaje que ya viene listo para mostrar.
class ErrorApi implements Exception {
  final int codigo;
  final String mensaje;

  ErrorApi(this.codigo, this.mensaje);

  @override
  String toString() => mensaje;
}

/// Cliente HTTP de la API.
///
/// La regla del auto-refresco (ADR 004) se implementa acá una sola vez:
/// si una petición autenticada responde 401, se renueva el token y se reintenta.
class ApiClient {
  final String baseUrl;
  final http.Client _http;
  final AlmacenSesion _almacen;

  ApiClient({String? baseUrl, http.Client? httpClient, AlmacenSesion? almacen})
      : baseUrl = baseUrl ?? Config.apiBaseUrl,
        _http = httpClient ?? http.Client(),
        _almacen = almacen ?? AlmacenSesion();

  /// Petición sin token (registro, login, logout).
  Future<Map<String, dynamic>> postPublico(
    String ruta,
    Map<String, dynamic> cuerpo,
  ) async {
    final respuesta = await _http.post(
      Uri.parse('$baseUrl$ruta'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(cuerpo),
    );
    return _decodificar(respuesta);
  }

  Future<Map<String, dynamic>> getAutenticado(String ruta) =>
      _conReintento((sesion) => _http.get(
            Uri.parse('$baseUrl$ruta'),
            headers: _cabeceras(sesion),
          ));

  Future<Map<String, dynamic>> postAutenticado(
    String ruta,
    Map<String, dynamic> cuerpo,
  ) =>
      _conReintento((sesion) => _http.post(
            Uri.parse('$baseUrl$ruta'),
            headers: {..._cabeceras(sesion), 'Content-Type': 'application/json'},
            body: jsonEncode(cuerpo),
          ));

  Map<String, String> _cabeceras(Sesion sesion) => {
        'Authorization': 'Bearer ${sesion.acceso}',
      };

  Future<Map<String, dynamic>> _conReintento(
    Future<http.Response> Function(Sesion) peticion,
  ) async {
    var sesion = await _almacen.leer();
    if (sesion == null) {
      throw ErrorApi(401, 'No hay sesión iniciada');
    }
    var respuesta = await peticion(sesion);
    if (respuesta.statusCode == 401) {
      sesion = await _refrescar(sesion);
      respuesta = await peticion(sesion);
    }
    return _decodificar(respuesta);
  }

  Future<Sesion> _refrescar(Sesion sesion) async {
    final respuesta = await _http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresco': sesion.refresco}),
    );
    if (respuesta.statusCode != 200) {
      await _almacen.borrar();
      throw ErrorApi(401, 'La sesión venció; volvé a entrar');
    }
    final nueva =
        Sesion.fromJson(jsonDecode(respuesta.body) as Map<String, dynamic>);
    await _almacen.guardar(nueva);
    return nueva;
  }

  Map<String, dynamic> _decodificar(http.Response respuesta) {
    final cuerpo = respuesta.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(respuesta.body);

    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      return cuerpo is Map<String, dynamic> ? cuerpo : {'datos': cuerpo};
    }

    var mensaje = 'Ocurrió un error (${respuesta.statusCode})';
    if (cuerpo is Map && cuerpo['error'] is Map) {
      mensaje = (cuerpo['error']['mensaje'] ?? mensaje).toString();
    }
    throw ErrorApi(respuesta.statusCode, mensaje);
  }
}
