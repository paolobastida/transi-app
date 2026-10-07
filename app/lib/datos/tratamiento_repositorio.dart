import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../dominio/tratamiento.dart';
import 'base_local.dart';

/// Repositorio local de tratamientos (offline-first).
class TratamientoRepositorio {
  final BaseLocal _base;

  TratamientoRepositorio(this._base);

  /// Lista reactiva. `estado` puede ser null (todos), "activo" o "finalizado".
  Stream<List<Tratamiento>> observar(String usuarioId, {String? estado}) {
    final consulta = _base.select(_base.tratamientos)
      ..where((t) {
        var filtro = t.usuarioId.equals(usuarioId) & t.activo.equals(true);
        if (estado == 'activo') {
          filtro = filtro & t.fechaFin.isNull();
        } else if (estado == 'finalizado') {
          filtro = filtro & t.fechaFin.isNotNull();
        }
        return filtro;
      })
      ..orderBy([
        (t) => OrderingTerm(expression: t.fechaInicio, mode: OrderingMode.desc),
      ]);
    return consulta.watch().map((filas) => filas.map(_aModelo).toList());
  }

  Future<Tratamiento> crear({
    required String usuarioId,
    required String nombre,
    required String dosis,
    required String frecuencia,
    required DateTime fechaInicio,
    DateTime? fechaFin,
    String? profesionalId,
  }) async {
    final tratamiento = Tratamiento(
      id: const Uuid().v4(),
      usuarioId: usuarioId,
      nombre: nombre,
      dosis: dosis,
      frecuencia: frecuencia,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      profesionalId: profesionalId,
    );
    await _base.into(_base.tratamientos).insert(_aCompanion(tratamiento));
    return tratamiento;
  }

  Future<void> actualizar(Tratamiento tratamiento) async {
    await (_base.update(_base.tratamientos)
          ..where((t) =>
              t.id.equals(tratamiento.id) &
              t.usuarioId.equals(tratamiento.usuarioId)))
        .write(TratamientosCompanion(
      nombre: Value(tratamiento.nombre),
      dosis: Value(tratamiento.dosis),
      frecuencia: Value(tratamiento.frecuencia),
      fechaInicio: Value(tratamiento.fechaInicio),
      fechaFin: Value(tratamiento.fechaFin),
      profesionalId: Value(tratamiento.profesionalId),
    ));
  }

  /// R5: borrado lógico.
  Future<void> desactivar(String id, String usuarioId) async {
    await (_base.update(_base.tratamientos)
          ..where((t) => t.id.equals(id) & t.usuarioId.equals(usuarioId)))
        .write(const TratamientosCompanion(activo: Value(false)));
  }

  Tratamiento _aModelo(FilaTratamiento fila) => Tratamiento(
        id: fila.id,
        usuarioId: fila.usuarioId,
        nombre: fila.nombre,
        dosis: fila.dosis,
        frecuencia: fila.frecuencia,
        fechaInicio: fila.fechaInicio,
        fechaFin: fila.fechaFin,
        profesionalId: fila.profesionalId,
        activo: fila.activo,
      );

  TratamientosCompanion _aCompanion(Tratamiento t) =>
      TratamientosCompanion.insert(
        id: t.id,
        usuarioId: t.usuarioId,
        nombre: t.nombre,
        dosis: t.dosis,
        frecuencia: t.frecuencia,
        fechaInicio: t.fechaInicio,
        fechaFin: Value(t.fechaFin),
        profesionalId: Value(t.profesionalId),
      );
}
