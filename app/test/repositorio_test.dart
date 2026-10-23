import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transi/datos/base_local.dart';
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

  test('guarda el profesional dentro del tratamiento', () async {
    final repo = TratamientoRepositorio(base);
    await repo.crear(
      usuarioId: 'u1',
      nombre: 'Testosterona',
      dosis: '100 mg',
      frecuencia: 'cada 14 días',
      fechaInicio: DateTime(2026, 1, 10),
      via: 'Inyectable',
      profesionalNombre: 'Dra. García',
      profesionalEspecialidad: 'Endocrinología',
    );

    final t = (await repo.observar('u1').first).single;
    expect(t.via, 'Inyectable');
    expect(t.profesionalNombre, 'Dra. García');
    expect(t.profesionalEspecialidad, 'Endocrinología');
  });

  test('sugiere los profesionales ya usados (sin repetir)', () async {
    final repo = TratamientoRepositorio(base);
    for (final nombre in ['Estradiol', 'Espironolactona']) {
      await repo.crear(
        usuarioId: 'u1',
        nombre: nombre,
        dosis: '1',
        frecuencia: 'd',
        fechaInicio: DateTime(2026, 1, 1),
        profesionalNombre: 'Dra. García',
        profesionalEspecialidad: 'Endocrinología',
      );
    }

    final usados = await repo.observarProfesionales('u1').first;
    expect(usados, hasLength(1));
    expect(usados.single.nombre, 'Dra. García');
    expect(usados.single.especialidad, 'Endocrinología');
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
    final repo = TratamientoRepositorio(base);
    await repo.crear(
      usuarioId: 'u1',
      nombre: 'Estradiol',
      dosis: '2 mg',
      frecuencia: 'cada día',
      fechaInicio: DateTime(2026, 1, 1),
    );

    expect(await repo.observar('u2').first, isEmpty);
    expect(await repo.observar('u1').first, hasLength(1));
  });
}
