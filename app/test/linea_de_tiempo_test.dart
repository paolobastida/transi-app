import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transi/datos/base_local.dart';
import 'package:transi/datos/cambio_repositorio.dart';
import 'package:transi/datos/linea_de_tiempo.dart';
import 'package:transi/datos/tratamiento_repositorio.dart';
import 'package:transi/dominio/evento_timeline.dart';

void main() {
  late BaseLocal base;
  late LineaDeTiempo linea;

  setUp(() {
    base = BaseLocal(NativeDatabase.memory());
    linea = LineaDeTiempo(
      cambios: CambioRepositorio(base),
      tratamientos: TratamientoRepositorio(base),
    );
  });
  tearDown(() => base.close());

  test('une tratamientos y cambios ordenados por fecha (más reciente primero)',
      () async {
    await CambioRepositorio(base).crear(
      usuarioId: 'u1',
      fecha: DateTime(2026, 1, 20),
      descripcion: 'cambio reciente',
      adjuntos: const [],
    );
    await TratamientoRepositorio(base).crear(
      usuarioId: 'u1',
      nombre: 'Estradiol',
      dosis: '2 mg',
      frecuencia: 'cada día',
      fechaInicio: DateTime(2026, 1, 10),
    );

    final eventos = await linea.observar('u1').first;
    expect(eventos, hasLength(2));
    expect(eventos.first.tipo, TipoEvento.cambio);
    expect(eventos.last.titulo, 'Estradiol');
  });

  test('filtra por rango de fechas', () async {
    await CambioRepositorio(base).crear(
      usuarioId: 'u1',
      fecha: DateTime(2026, 1, 5),
      descripcion: 'viejo',
      adjuntos: const [],
    );
    await CambioRepositorio(base).crear(
      usuarioId: 'u1',
      fecha: DateTime(2026, 1, 25),
      descripcion: 'nuevo',
      adjuntos: const [],
    );

    final eventos =
        await linea.observar('u1', desde: DateTime(2026, 1, 15)).first;
    expect(eventos, hasLength(1));
    expect(eventos.first.titulo, 'nuevo');
  });
}
