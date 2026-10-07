import 'dart:convert';

import 'package:drift/drift.dart';

import 'api_client.dart';
import 'base_local.dart';

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
class RespaldoServicio {
  static const _claveUltimo = 'ultimo_respaldo_en';

  final BaseLocal _base;
  final RespaldoRemoto _remoto;

  RespaldoServicio(this._base, this._remoto);

  /// Cuántos registros cambiaron desde el último respaldo.
  Future<int> pendientes() async {
    final profesionales = await (_base.select(_base.profesionales)
          ..where((t) => t.pendiente.equals(true)))
        .get();
    final tratamientos = await (_base.select(_base.tratamientos)
          ..where((t) => t.pendiente.equals(true)))
        .get();
    final cambios = await (_base.select(_base.cambios)
          ..where((t) => t.pendiente.equals(true)))
        .get();
    return profesionales.length + tratamientos.length + cambios.length;
  }

  Future<DateTime?> ultimoRespaldo() async {
    final fila = await (_base.select(_base.ajustes)
          ..where((a) => a.clave.equals(_claveUltimo)))
        .getSingleOrNull();
    if (fila == null) return null;
    return DateTime.tryParse(fila.valor)?.toLocal();
  }

  /// Sube el snapshot completo y marca todo como respaldado.
  Future<void> respaldar(String usuarioId) async {
    final snapshot = await _construirSnapshot();
    await _remoto.subir(jsonEncode(snapshot));
    await _marcarRespaldado();
  }

  /// Baja el último snapshot y reemplaza los datos locales.
  Future<void> restaurar(String usuarioId) async {
    final crudo = await _remoto.bajar();
    final snapshot = jsonDecode(crudo) as Map<String, dynamic>;
    await _reemplazarTodo(usuarioId, snapshot);
  }

  Future<Map<String, dynamic>> _construirSnapshot() async {
    final profesionales = await _base.select(_base.profesionales).get();
    final tratamientos = await _base.select(_base.tratamientos).get();
    final cambios = await _base.select(_base.cambios).get();
    final adjuntos = await _base.select(_base.adjuntos).get();

    return {
      'version': 1,
      'generadoEn': DateTime.now().toUtc().toIso8601String(),
      'profesionales': [
        for (final p in profesionales)
          {
            'id': p.id,
            'nombre': p.nombre,
            'especialidad': p.especialidad,
            'activo': p.activo,
          },
      ],
      'tratamientos': [
        for (final t in tratamientos)
          {
            'id': t.id,
            'nombre': t.nombre,
            'dosis': t.dosis,
            'frecuencia': t.frecuencia,
            'fechaInicio': t.fechaInicio.toIso8601String(),
            'fechaFin': t.fechaFin?.toIso8601String(),
            'profesionalId': t.profesionalId,
            'activo': t.activo,
          },
      ],
      'cambios': [
        for (final c in cambios)
          {
            'id': c.id,
            'fecha': c.fecha.toIso8601String(),
            'descripcion': c.descripcion,
            'activo': c.activo,
            'adjuntos': [
              for (final a in adjuntos.where((a) => a.cambioId == c.id))
                {
                  'id': a.id,
                  'tipo': a.tipo,
                  'nombre': a.nombre,
                  'contenido': base64Encode(a.contenido),
                },
            ],
          },
      ],
    };
  }

  Future<void> _reemplazarTodo(
    String usuarioId,
    Map<String, dynamic> snapshot,
  ) async {
    await _base.transaction(() async {
      await _base.delete(_base.adjuntos).go();
      await _base.delete(_base.cambios).go();
      await _base.delete(_base.tratamientos).go();
      await _base.delete(_base.profesionales).go();

      for (final crudo in (snapshot['profesionales'] as List? ?? [])) {
        final m = crudo as Map<String, dynamic>;
        await _base.into(_base.profesionales).insert(
              ProfesionalesCompanion.insert(
                id: m['id'] as String,
                usuarioId: usuarioId,
                nombre: m['nombre'] as String,
                especialidad: m['especialidad'] as String,
                activo: Value(m['activo'] as bool? ?? true),
                pendiente: const Value(false),
              ),
            );
      }

      for (final crudo in (snapshot['tratamientos'] as List? ?? [])) {
        final m = crudo as Map<String, dynamic>;
        await _base.into(_base.tratamientos).insert(
              TratamientosCompanion.insert(
                id: m['id'] as String,
                usuarioId: usuarioId,
                nombre: m['nombre'] as String,
                dosis: m['dosis'] as String,
                frecuencia: m['frecuencia'] as String,
                fechaInicio: DateTime.parse(m['fechaInicio'] as String),
                fechaFin: Value(m['fechaFin'] == null
                    ? null
                    : DateTime.parse(m['fechaFin'] as String)),
                profesionalId: Value(m['profesionalId'] as String?),
                activo: Value(m['activo'] as bool? ?? true),
                pendiente: const Value(false),
              ),
            );
      }

      for (final crudo in (snapshot['cambios'] as List? ?? [])) {
        final m = crudo as Map<String, dynamic>;
        await _base.into(_base.cambios).insert(
              CambiosCompanion.insert(
                id: m['id'] as String,
                usuarioId: usuarioId,
                fecha: DateTime.parse(m['fecha'] as String),
                descripcion: Value(m['descripcion'] as String? ?? ''),
                activo: Value(m['activo'] as bool? ?? true),
                pendiente: const Value(false),
              ),
            );
        for (final crudoAdjunto in (m['adjuntos'] as List? ?? [])) {
          final a = crudoAdjunto as Map<String, dynamic>;
          await _base.into(_base.adjuntos).insert(
                AdjuntosCompanion.insert(
                  id: a['id'] as String,
                  cambioId: m['id'] as String,
                  tipo: a['tipo'] as String,
                  contenido: base64Decode(a['contenido'] as String),
                  nombre: Value(a['nombre'] as String? ?? ''),
                ),
              );
        }
      }
    });
  }

  Future<void> _marcarRespaldado() async {
    await _base.transaction(() async {
      await (_base.update(_base.profesionales)
            ..where((t) => t.pendiente.equals(true)))
          .write(const ProfesionalesCompanion(pendiente: Value(false)));
      await (_base.update(_base.tratamientos)
            ..where((t) => t.pendiente.equals(true)))
          .write(const TratamientosCompanion(pendiente: Value(false)));
      await (_base.update(_base.cambios)
            ..where((t) => t.pendiente.equals(true)))
          .write(const CambiosCompanion(pendiente: Value(false)));
      await _base.into(_base.ajustes).insertOnConflictUpdate(
            AjustesCompanion.insert(
              clave: _claveUltimo,
              valor: DateTime.now().toUtc().toIso8601String(),
            ),
          );
    });
  }
}
