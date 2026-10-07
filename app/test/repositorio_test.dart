import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transi/datos/base_local.dart';
import 'package:transi/datos/profesional_repositorio.dart';
import 'package:transi/datos/tratamiento_repositorio.dart';

void main() {
  late BaseLocal base;

  setUp(() => base = BaseLocal(NativeDatabase.memory()));
  tearDown(() => base.close());

  test('crear y listar tratamientos', () async {
    final repo = TratamientoRepositorio(base);
    await repo.crear(
      usuarioId: 'u1',
      nombre: 'Estradiol',
      dosis: '2 mg',
      frecuencia: 'cada día',
      fechaInicio: DateTime(2026, 1, 10),
    );

    final lista = await repo.observar('u1').first;
    expect(lista, hasLength(1));
    expect(lista.first.nombre, 'Estradiol');
    expect(lista.first.finalizado, isFalse);
  });

  test('desactivar tratamiento aplica borrado lógico (R5)', () async {
    final repo = TratamientoRepositorio(base);
    final tratamiento = await repo.crear(
      usuarioId: 'u1',
      nombre: 'Estradiol',
      dosis: '2 mg',
      frecuencia: 'cada día',
      fechaInicio: DateTime(2026, 1, 10),
    );

    await repo.desactivar(tratamiento.id, 'u1');
    expect(await repo.observar('u1').first, isEmpty);
  });

  test('filtrar por estado activo/finalizado', () async {
    final repo = TratamientoRepositorio(base);
    await repo.crear(
      usuarioId: 'u1',
      nombre: 'Activo',
      dosis: '1',
      frecuencia: 'd',
      fechaInicio: DateTime(2026, 1, 1),
    );
    await repo.crear(
      usuarioId: 'u1',
      nombre: 'Cerrado',
      dosis: '1',
      frecuencia: 'd',
      fechaInicio: DateTime(2026, 1, 1),
      fechaFin: DateTime(2026, 6, 1),
    );

    final activos = await repo.observar('u1', estado: 'activo').first;
    final finalizados = await repo.observar('u1', estado: 'finalizado').first;
    expect(activos.map((t) => t.nombre), ['Activo']);
    expect(finalizados.map((t) => t.nombre), ['Cerrado']);
  });

  test('un usuario no ve datos de otro (R1)', () async {
    final repo = ProfesionalRepositorio(base);
    await repo.crear(usuarioId: 'u1', nombre: 'Dra. López', especialidad: 'Endocrinología');

    expect(await repo.observar('u2').first, isEmpty);
    expect(await repo.observar('u1').first, hasLength(1));
  });
}
