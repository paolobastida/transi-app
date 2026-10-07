import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../dominio/profesional.dart';
import 'base_local.dart';

/// Repositorio local de profesionales. La interfaz lee y escribe acá; el
/// servidor no se usa para esta pantalla (offline-first).
class ProfesionalRepositorio {
  final BaseLocal _base;

  ProfesionalRepositorio(this._base);

  Stream<List<Profesional>> observar(String usuarioId) {
    final consulta = _base.select(_base.profesionales)
      ..where((t) => t.usuarioId.equals(usuarioId) & t.activo.equals(true))
      ..orderBy([(t) => OrderingTerm(expression: t.nombre)]);
    return consulta.watch().map((filas) => filas.map(_aModelo).toList());
  }

  Future<Profesional> crear({
    required String usuarioId,
    required String nombre,
    required String especialidad,
  }) async {
    final profesional = Profesional(
      id: const Uuid().v4(),
      usuarioId: usuarioId,
      nombre: nombre,
      especialidad: especialidad,
    );
    await _base.into(_base.profesionales).insert(_aCompanion(profesional));
    return profesional;
  }

  Future<void> actualizar(Profesional profesional) async {
    await (_base.update(_base.profesionales)
          ..where((t) =>
              t.id.equals(profesional.id) &
              t.usuarioId.equals(profesional.usuarioId)))
        .write(ProfesionalesCompanion(
      nombre: Value(profesional.nombre),
      especialidad: Value(profesional.especialidad),
    ));
  }

  /// R5: borrado lógico.
  Future<void> desactivar(String id, String usuarioId) async {
    await (_base.update(_base.profesionales)
          ..where((t) => t.id.equals(id) & t.usuarioId.equals(usuarioId)))
        .write(const ProfesionalesCompanion(activo: Value(false)));
  }

  Profesional _aModelo(FilaProfesional fila) => Profesional(
        id: fila.id,
        usuarioId: fila.usuarioId,
        nombre: fila.nombre,
        especialidad: fila.especialidad,
        activo: fila.activo,
      );

  ProfesionalesCompanion _aCompanion(Profesional p) =>
      ProfesionalesCompanion.insert(
        id: p.id,
        usuarioId: p.usuarioId,
        nombre: p.nombre,
        especialidad: p.especialidad,
      );
}
