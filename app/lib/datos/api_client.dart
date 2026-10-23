import 'dart:async';
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

  /// Refresh en vuelo. Sin este mutex, dos peticiones que reciben 401 a la vez
  /// llamaban a `/auth/refresh` con el mismo token; como el servidor rota e
  /// invalida el anterior, la segunda fallaba y terminaba **cerrando la sesión
  /// del usuario**. Ahora la segunda espera a la primera y reutiliza el token.
  Future<Sesion>? _refrescoEnCurso;

  /// Tope de espera de cada petición. Sin esto, una red que acepta la conexión
  /// y no responde deja el botón cargando indefinidamente.
  static const Duration _timeout = Duration(seconds: 20);

  /// Los respaldos llevan fotos y audios: necesitan más margen que una
  /// petición normal.
  static const Duration _timeoutRespaldo = Duration(minutes: 2);

  ApiClient({String? baseUrl, http.Client? httpClient, AlmacenSesion? almacen})
      : baseUrl = baseUrl ?? Config.apiBaseUrl,
        _http = httpClient ?? http.Client(),
        _almacen = almacen ?? AlmacenSesion();

  /// Petición sin token (registro, login, logout).
  Future<Map<String, dynamic>> postPublico(
    String ruta,
    Map<String, dynamic> cuerpo,
  ) async {
    try {
      final respuesta = await _http
          .post(
            Uri.parse('$baseUrl$ruta'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(cuerpo),
          )
          .timeout(_timeout);
      return _decodificar(respuesta);
    } on TimeoutException {
      throw ErrorApi(0, 'No pudimos conectar. Revisá tu conexión.');
    } on http.ClientException {
      throw ErrorApi(0, 'No pudimos conectar. Revisá tu conexión.');
    }
  }

  Future<Map<String, dynamic>> getAutenticado(String ruta) => _conReintento(
        (sesion) => _http
            .get(Uri.parse('$baseUrl$ruta'), headers: _cabeceras(sesion))
            .timeout(_timeout),
      );

  Future<Map<String, dynamic>> postAutenticado(
    String ruta,
    Map<String, dynamic> cuerpo,
  ) =>
      _conReintento((sesion) => _http
          .post(
            Uri.parse('$baseUrl$ruta'),
            headers: {..._cabeceras(sesion), 'Content-Type': 'application/json'},
            body: jsonEncode(cuerpo),
          )
          .timeout(_timeout));

  Map<String, String> _cabeceras(Sesion sesion) => {
        'Authorization': 'Bearer ${sesion.acceso}',
      };

  /// Sube un cuerpo ya serializado (usado por el respaldo) con el token.
  Future<void> putTextoAutenticado(String ruta, String cuerpo) async {
    final respuesta = await _peticionConReintento(
      (sesion) => _http
          .put(
            Uri.parse('$baseUrl$ruta'),
            headers: {..._cabeceras(sesion), 'Content-Type': 'application/json'},
            body: cuerpo,
          )
          .timeout(_timeoutRespaldo),
    );
    if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
      throw ErrorApi(respuesta.statusCode, 'No se pudo subir el respaldo');
    }
  }

  /// Baja un cuerpo de texto (usado por el respaldo) con el token.
  Future<String> getTextoAutenticado(String ruta) async {
    final respuesta = await _peticionConReintento(
      (sesion) => _http
          .get(Uri.parse('$baseUrl$ruta'), headers: _cabeceras(sesion))
          .timeout(_timeoutRespaldo),
    );
    if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
      throw ErrorApi(respuesta.statusCode, 'No se pudo bajar el respaldo');
    }
    return respuesta.body;
  }

  Future<Map<String, dynamic>> _conReintento(
    Future<http.Response> Function(Sesion) peticion,
  ) async {
    final respuesta = await _peticionConReintento(peticion);
    return _decodificar(respuesta);
  }

  /// Hace una petición autenticada y, si responde 401, renueva el token y
  /// reintenta **una sola vez**.
  ///
  /// Es el único lugar donde vive la regla del auto-refresco (ADR 004); antes
  /// estaba copiada en cada método que usaba el token.
  Future<http.Response> _peticionConReintento(
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
    return respuesta;
  }

  /// Renueva el token **una sola vez** aunque varias peticiones lo pidan a la
  /// vez. Las que llegan mientras corre esperan su resultado en vez de gastar
  /// el mismo refresh (que el servidor invalida al rotarlo).
  Future<Sesion> _refrescar(Sesion sesion) {
    return _refrescoEnCurso ??= _hacerRefresh(sesion).whenComplete(() {
      _refrescoEnCurso = null;
    });
  }

  Future<Sesion> _hacerRefresh(Sesion sesion) async {
    final respuesta = await _http
        .post(
          Uri.parse('$baseUrl/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresco': sesion.refresco}),
        )
        .timeout(_timeout);

    if (respuesta.statusCode == 401 || respuesta.statusCode == 403) {
      // Solo un 401/403 del refresh significa que la sesión realmente venció.
      // Ante un 5xx o un problema de red NO se borra la sesión: un pico de
      // carga del servidor no debe expulsar a todos los usuarios de la app.
      await _almacen.borrar();
      throw ErrorApi(401, 'La sesión venció; volvé a entrar');
    }
    if (respuesta.statusCode < 200 || respuesta.statusCode >= 300) {
      throw ErrorApi(respuesta.statusCode,
          'No pudimos renovar la sesión. Probá de nuevo en un momento.');
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
