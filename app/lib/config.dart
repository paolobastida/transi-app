/// Configuración de la app.
///
/// La URL del servidor se cambia al compilar con:
///   flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080
///
/// En un build de publicación **tiene que ser https://**: en claro viajarían la
/// contraseña, los tokens y los respaldos (con fotos y notas de voz). El
/// servidor en `main()` falla el arranque si no se cumple.
library;

import 'package:flutter/foundation.dart' show kReleaseMode;

class Config {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// `true` solo en builds de debug, donde se permite hablar con el servidor
  /// local por HTTP.
  static bool get enDebug => !kReleaseMode;
}