/// Configuración de la app.
///
/// La URL del servidor se puede cambiar al compilar con:
///   flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080
class Config {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
