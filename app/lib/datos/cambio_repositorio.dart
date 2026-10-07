import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../dominio/cambio.dart';
import 'base_local.dart';

/// Repositorio local de cambios (offline-first). Guarda el cambio y sus
/// adjuntos en una sola transacción: o se guardan todos, o ninguno.
class CambioRepositorio {
  final BaseLocal _base;

  CambioRepositorio(this._base);

  Stream<List<Cambio>> observar(String usuarioId) {
    final consulta = _base.select(_base.cambios)
      ..where((t) => t.usuarioId.equals(usuarioId) & t.activo.equals(true))
      ..orderBy([
        (t) => OrderingTerm(expression: t.fecha, mode: OrderingMode.desc),
      ]);

    return consulta.watch().asyncMap((filas) async {
      final cambios = <Cambio>[];
      for (final fila in filas) {
        cambios.add(await _conAdjuntos(fila));
      }
      return cambios;
    });
  }

  Future<Cambio> crear({
    required String usuarioId,
    required DateTime fecha,
    required String descripcion,
    required List<EntradaAdjunto> adjuntos,
  }) async {
    final id = const Uuid().v4();
    final creados = <Adjunto>[];

    await _base.transaction(() async {
      await _base.into(_base.cambios).insert(CambiosCompanion.insert(
            id: id,
            usuarioId: usuarioId,
            fecha: fecha,
            descripcion: Value(descripcion),
          ));
      for (final entrada in adjuntos) {
        final adjunto = Adjunto(
          id: const Uuid().v4(),
          cambioId: id,
          tipo: entrada.tipo,
          nombre: entrada.nombre,
          contenido: entrada.contenido,
        );
        creados.add(adjunto);
        await _base.into(_base.adjuntos).insert(AdjuntosCompanion.insert(
              id: adjunto.id,
              cambioId: adjunto.cambioId,
              tipo: adjunto.tipo,
              contenido: adjunto.contenido,
              nombre: Value(adjunto.nombre),
            ));
      }
    });

    return Cambio(
      id: id,
      usuarioId: usuarioId,
      fecha: fecha,
      descripcion: descripcion,
      adjuntos: creados,
    );
  }

  Future<void> desactivar(String id, String usuarioId) async {
    await (_base.update(_base.cambios)
          ..where((t) => t.id.equals(id) & t.usuarioId.equals(usuarioId)))
        .write(const CambiosCompanion(
      activo: Value(false),
      pendiente: Value(true),
    ));
  }

  Future<Cambio> _conAdjuntos(FilaCambio fila) async {
    final adjuntos = await (_base.select(_base.adjuntos)
          ..where((a) => a.cambioId.equals(fila.id)))
        .get();
    return Cambio(
      id: fila.id,
      usuarioId: fila.usuarioId,
      fecha: fila.fecha,
      descripcion: fila.descripcion,
      activo: fila.activo,
      adjuntos: adjuntos
          .map((a) => Adjunto(
                id: a.id,
                cambioId: a.cambioId,
                tipo: a.tipo,
                nombre: a.nombre,
                contenido: a.contenido,
              ))
          .toList(),
    );
  }
}
