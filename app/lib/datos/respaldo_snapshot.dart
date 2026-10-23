import 'dart:convert';

import 'package:drift/drift.dart';

import 'base_local.dart';

/// Traduce entre los datos locales y el **formato JSON** del respaldo.
///
/// Una sola responsabilidad: cómo se serializa y se vuelve a escribir un
/// snapshot. No sabe de red ni de cuándo respaldar: eso lo decide
/// [RespaldoServicio]. Tener el formato en un solo lugar hace que la "prueba
/// madre" (respaldar y restaurar deja todo igual) cubra exactamente este
/// contrato.
class SnapshotLocal {
  static const _claveUltimo = 'ultimo_respaldo_en';

  final BaseLocal _base;

  SnapshotLocal(this._base);

  /// Cuántos registros del [usuarioId] cambiaron desde el último respaldo.
  ///
  /// Cuenta **solo** los del usuario indicado: la base puede tener filas de
  /// una sesión anterior en el mismo dispositivo y esos datos no son de esta
  /// cuenta (ni deben contarse ni enviarse).
  Future<int> pendientes(String usuarioId) async {
    final tratamientos = await (_base.select(_base.tratamientos)
          ..where(
              (t) => t.usuarioId.equals(usuarioId) & t.pendiente.equals(true)))
        .get();
    final cambios = await (_base.select(_base.cambios)
          ..where(
              (t) => t.usuarioId.equals(usuarioId) & t.pendiente.equals(true)))
        .get();
    return tratamientos.length + cambios.length;
  }

  Future<DateTime?> ultimoRespaldo() async {
    final fila = await (_base.select(_base.ajustes)
          ..where((a) => a.clave.equals(_claveUltimo)))
        .getSingleOrNull();
    if (fila == null) return null;
    return DateTime.tryParse(fila.valor)?.toLocal();
  }

  /// Arma el snapshot **solo con los datos de [usuarioId]**.
  ///
  /// Cada tabla tiene `usuario_id`. Filtrar acá es lo que impide que los datos
  /// clínicos de otra cuenta que quedó en el dispositivo viajen al respaldo.
  Future<Map<String, dynamic>> construir(String usuarioId) async {
    final tratamientos = await (_base.select(_base.tratamientos)
          ..where((t) => t.usuarioId.equals(usuarioId)))
        .get();
    final cambios = await (_base.select(_base.cambios)
          ..where((t) => t.usuarioId.equals(usuarioId)))
        .get();
    // Los adjuntos cuelgan de un cambio: se toman solo los de estos cambios.
    final idsDeCambios = cambios.map((c) => c.id).toSet();
    final adjuntos = await (_base.select(_base.adjuntos)
          ..where((t) => t.cambioId.isIn(idsDeCambios)))
        .get();

    return {
      'version': 2,
      'generadoEn': DateTime.now().toUtc().toIso8601String(),
      'tratamientos': [
        for (final t in tratamientos)
          {
            'id': t.id,
            'nombre': t.nombre,
            'dosis': t.dosis,
            'frecuencia': t.frecuencia,
            'fechaInicio': t.fechaInicio.toIso8601String(),
            'fechaFin': t.fechaFin?.toIso8601String(),
            'activo': t.activo,
            'via': t.via,
            'presentacion': t.presentacion,
            'dosisCantidad': t.dosisCantidad,
            'dosisUnidad': t.dosisUnidad,
            'indicacion': t.indicacion,
            'profesionalNombre': t.profesionalNombre,
            'profesionalEspecialidad': t.profesionalEspecialidad,
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

  /// Reemplaza los datos locales del [usuarioId] por los del [snapshot].
  Future<void> reemplazar(
    String usuarioId,
    Map<String, dynamic> snapshot,
  ) async {
    await _base.transaction(() async {
      await _base.delete(_base.adjuntos).go();
      await _base.delete(_base.cambios).go();
      await _base.delete(_base.tratamientos).go();

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
                via: Value(m['via'] as String?),
                presentacion: Value(m['presentacion'] as String?),
                dosisCantidad: Value((m['dosisCantidad'] as num?)?.toDouble()),
                dosisUnidad: Value(m['dosisUnidad'] as String?),
                indicacion: Value(m['indicacion'] as String?),
                profesionalNombre: Value(m['profesionalNombre'] as String?),
                profesionalEspecialidad:
                    Value(m['profesionalEspecialidad'] as String?),
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

  /// Marca como respaldado todo lo pendiente del [usuarioId] y anota la hora.
  Future<void> marcarRespaldado(String usuarioId) async {
    await _base.transaction(() async {
      await (_base.update(_base.tratamientos)
            ..where((t) =>
                t.usuarioId.equals(usuarioId) & t.pendiente.equals(true)))
          .write(const TratamientosCompanion(pendiente: Value(false)));
      await (_base.update(_base.cambios)
            ..where((t) =>
                t.usuarioId.equals(usuarioId) & t.pendiente.equals(true)))
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
