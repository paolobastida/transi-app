import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transi/datos/base_local.dart';
import 'package:transi/datos/cambio_repositorio.dart';
import 'package:transi/datos/respaldo.dart';
import 'package:transi/datos/tratamiento_repositorio.dart';
import 'package:transi/dominio/cambio.dart';

/// Servidor de respaldo falso: guarda el snapshot en memoria.
class RespaldoRemotoFalso implements RespaldoRemoto {
  String? guardado;

  @override
  Future<void> subir(String snapshot) async => guardado = snapshot;

  @override
  Future<String> bajar() async {
    if (guardado == null) throw Exception('no hay respaldo');
    return guardado!;
  }
}

void main() {
  test('prueba madre: respaldar y restaurar en otra base deja todo igual',
      () async {
    final origen = BaseLocal(NativeDatabase.memory());
    final destino = BaseLocal(NativeDatabase.memory());
    final remoto = RespaldoRemotoFalso();
    addTearDown(() async {
      await origen.close();
      await destino.close();
    });

    // 1. Datos en el dispositivo de origen.
    await TratamientoRepositorio(origen).crear(
      usuarioId: 'u1',
      nombre: 'Estradiol',
      dosis: '2 mg',
      frecuencia: 'cada día',
      fechaInicio: DateTime(2026, 1, 10),
      profesionalNombre: 'Dra. López',
      profesionalEspecialidad: 'Endocrinología',
    );
    await CambioRepositorio(origen).crear(
      usuarioId: 'u1',
      fecha: DateTime(2026, 1, 20),
      descripcion: 'noté cambios en la voz',
      adjuntos: [
        EntradaAdjunto(
          tipo: 'foto',
          nombre: 'foto.jpg',
          contenido: Uint8List.fromList([1, 2, 3, 4]),
        ),
      ],
    );

    // 2. Respaldar.
    final servicioOrigen = RespaldoServicio(origen, remoto);
    await servicioOrigen.respaldar('u1');
    expect(await servicioOrigen.pendientes('u1'), 0);
    expect(await servicioOrigen.ultimoRespaldo(), isNotNull);

    // 3. Restaurar en un dispositivo nuevo.
    await RespaldoServicio(destino, remoto).restaurar('u1');

    // 4. Todo igual, incluido el profesional dentro del tratamiento.
    final tratamientos =
        await TratamientoRepositorio(destino).observar('u1').first;
    final cambios = await CambioRepositorio(destino).observar('u1').first;

    expect(tratamientos, hasLength(1));
    expect(tratamientos.first.nombre, 'Estradiol');
    expect(tratamientos.first.profesionalNombre, 'Dra. López');
    expect(tratamientos.first.profesionalEspecialidad, 'Endocrinología');
    expect(cambios, hasLength(1));
    expect(cambios.first.descripcion, 'noté cambios en la voz');
    expect(cambios.first.adjuntos.first.contenido,
        Uint8List.fromList([1, 2, 3, 4]));
  });

  test('un cambio nuevo vuelve a marcar pendientes', () async {
    final base = BaseLocal(NativeDatabase.memory());
    addTearDown(base.close);
    final servicio = RespaldoServicio(base, RespaldoRemotoFalso());

    await TratamientoRepositorio(base).crear(
      usuarioId: 'u1',
      nombre: 'Estradiol',
      dosis: '2 mg',
      frecuencia: 'cada día',
      fechaInicio: DateTime(2026, 1, 1),
    );
    expect(await servicio.pendientes('u1'), 1);

    await servicio.respaldar('u1');
    expect(await servicio.pendientes('u1'), 0);
  });
}
