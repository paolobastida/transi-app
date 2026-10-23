import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transi/datos/base_local.dart';
import 'package:transi/datos/cambio_repositorio.dart';
import 'package:transi/datos/respaldo.dart';
import 'package:transi/datos/tratamiento_repositorio.dart';
import 'package:transi/dominio/cambio.dart';

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
  test('el respaldo de un usuario NO incluye datos de otro en el mismo '
      'dispositivo', () async {
    final base = BaseLocal(NativeDatabase.memory());
    final remoto = RespaldoRemotoFalso();
    addTearDown(base.close);

    // u1 deja datos clínicos y una foto en el dispositivo.
    await TratamientoRepositorio(base).crear(
      usuarioId: 'u1',
      nombre: 'Ciproterona',
      dosis: '50 mg',
      frecuencia: 'cada día',
      fechaInicio: DateTime(2026, 1, 10),
      profesionalNombre: 'Dra. Secreto',
      profesionalEspecialidad: 'Endocrinología',
    );
    await CambioRepositorio(base).crear(
      usuarioId: 'u1',
      fecha: DateTime(2026, 1, 20),
      descripcion: 'DATO MÉDICO SECRETO DE U1',
      adjuntos: [
        EntradaAdjunto(
          tipo: 'foto',
          nombre: 'foto-secreta.jpg',
          contenido: Uint8List.fromList([9, 9, 9, 9, 9]),
        ),
      ],
    );

    // u2 usa el mismo dispositivo (otra cuenta, típico de un teléfono
    // compartido): solo crea su propio tratamiento.
    await TratamientoRepositorio(base).crear(
      usuarioId: 'u2',
      nombre: 'Estradiol',
      dosis: '2 mg',
      frecuencia: 'cada día',
      fechaInicio: DateTime(2026, 2, 1),
    );

    final servicio = RespaldoServicio(base, remoto);
    await servicio.respaldar('u2');

    final snapshot = jsonDecode(remoto.guardado!) as Map<String, dynamic>;

    // Lo que se sube a la cuenta de u2 no puede traer nada de u1.
    expect(remoto.guardado, isNot(contains('DATO MÉDICO SECRETO DE U1')),
        reason: 'la descripción clínica de u1 subió al respaldo de u2');
    expect(remoto.guardado, isNot(contains('Ciproterona')),
        reason: 'el tratamiento de u1 subió al respaldo de u2');
    expect(remoto.guardado, isNot(contains('Dra. Secreto')),
        reason: 'el profesional de u1 subió al respaldo de u2');

    expect(snapshot['tratamientos'], hasLength(1));
    expect(
      (snapshot['tratamientos'] as List).first['nombre'],
      'Estradiol',
    );
    expect(snapshot['cambios'], isEmpty);
  });

  test('los pendientes de un usuario no cuentan los de otro', () async {
    final base = BaseLocal(NativeDatabase.memory());
    addTearDown(base.close);
    final servicio = RespaldoServicio(base, RespaldoRemotoFalso());

    await TratamientoRepositorio(base).crear(
      usuarioId: 'u1',
      nombre: 'Ciproterona',
      dosis: '50 mg',
      frecuencia: 'cada día',
      fechaInicio: DateTime(2026, 1, 10),
    );
    await TratamientoRepositorio(base).crear(
      usuarioId: 'u2',
      nombre: 'Estradiol',
      dosis: '2 mg',
      frecuencia: 'cada día',
      fechaInicio: DateTime(2026, 2, 1),
    );

    // u2 tiene un solo registro pendiente propio, no dos.
    expect(await servicio.pendientes('u2'), 1);

    // Respaldar como u2 no debe marcar como respaldados los datos de u1.
    await servicio.respaldar('u2');
    expect(await servicio.pendientes('u1'), 1,
        reason: 'u1 quedó marcado como respaldado sin que su backup lo incluyera');
    expect(await servicio.pendientes('u2'), 0);
  });
}