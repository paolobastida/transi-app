import 'dart:convert';

import 'api_client.dart';
import 'base_local.dart';
import 'respaldo_snapshot.dart';

/// Acceso remoto al respaldo. Es una interfaz para poder usar un doble en los
/// tests (sin red).
abstract class RespaldoRemoto {
  Future<void> subir(String snapshot);
  Future<String> bajar();
}

/// Implementación real: habla con la API (`PUT /respaldos`, `GET /respaldos/ultimo`).
class RespaldoApi implements RespaldoRemoto {
  final ApiClient _api;

  RespaldoApi(this._api);

  @override
  Future<void> subir(String snapshot) =>
      _api.putTextoAutenticado('/respaldos', snapshot);

  @override
  Future<String> bajar() => _api.getTextoAutenticado('/respaldos/ultimo');
}

/// U16 · Respaldar y restaurar (del lado de la app).
///
/// El respaldo es un **snapshot completo** de los datos locales (incluidos los
/// archivos, en base64). Restaurar reemplaza todo lo local por el snapshot.
///
/// Esta clase solo **orquesta**: pide el snapshot a [SnapshotLocal] (que sabe
/// el formato) y lo mueve con [RespaldoRemoto] (que sabe de red). Así puede
/// cambiar el transporte (Firebase, disco) sin tocar cómo se arma el respaldo,
/// y viceversa.
class RespaldoServicio {
  final SnapshotLocal _snapshot;
  final RespaldoRemoto _remoto;

  RespaldoServicio(BaseLocal base, this._remoto) : _snapshot = SnapshotLocal(base);

  /// Cuántos registros del usuario cambiaron desde el último respaldo.
  Future<int> pendientes(String usuarioId) => _snapshot.pendientes(usuarioId);

  Future<DateTime?> ultimoRespaldo() => _snapshot.ultimoRespaldo();

  /// Sube el snapshot completo y marca todo como respaldado.
  Future<void> respaldar(String usuarioId) async {
    final snapshot = await _snapshot.construir(usuarioId);
    await _remoto.subir(jsonEncode(snapshot));
    await _snapshot.marcarRespaldado(usuarioId);
  }

  /// Baja el último snapshot y reemplaza los datos locales.
  Future<void> restaurar(String usuarioId) async {
    final crudo = await _remoto.bajar();
    final snapshot = jsonDecode(crudo) as Map<String, dynamic>;
    await _snapshot.reemplazar(usuarioId, snapshot);
  }
}
