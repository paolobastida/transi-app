import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transi/datos/base_local.dart';
import 'package:transi/datos/cambio_repositorio.dart';
import 'package:transi/dominio/cambio.dart';

void main() {
  late BaseLocal base;

  setUp(() => base = BaseLocal(NativeDatabase.memory()));
  tearDown(() => base.close());

  test('registrar cambio con foto y voz, y listarlo', () async {
    final repo = CambioRepositorio(base);

    await repo.crear(
      usuarioId: 'u1',
      fecha: DateTime(2026, 1, 10),
      descripcion: 'noté cambios en la voz',
      adjuntos: [
        EntradaAdjunto(
          tipo: 'foto',
          nombre: 'foto.jpg',
          contenido: Uint8List.fromList([1, 2, 3]),
        ),
        EntradaAdjunto(
          tipo: 'audio',
          nombre: 'nota.m4a',
          contenido: Uint8List.fromList([4, 5, 6]),
        ),
      ],
    );

    final lista = await repo.observar('u1').first;
    expect(lista, hasLength(1));
    expect(lista.first.adjuntos, hasLength(2));
    expect(lista.first.adjuntos.first.contenido, Uint8List.fromList([1, 2, 3]));
    expect(lista.first.adjuntos.any((a) => a.esAudio), isTrue);
  });

  test('desactivar un cambio aplica borrado lógico (R5)', () async {
    final repo = CambioRepositorio(base);
    final cambio = await repo.crear(
      usuarioId: 'u1',
      fecha: DateTime(2026, 1, 1),
      descripcion: 'algo',
      adjuntos: const [],
    );

    await repo.desactivar(cambio.id, 'u1');
    expect(await repo.observar('u1').first, isEmpty);
  });
}
