import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:transi/datos/base_local.dart';
import 'package:transi/datos/tratamiento_repositorio.dart';

/// Verifica la migración v3 → v4: los profesionales guardados en su tabla se
/// copian al tratamiento y la tabla `profesionales` se elimina.
void main() {
  test('migra v3 → v4 copiando el profesional dentro del tratamiento', () async {
    final carpeta = Directory.systemTemp.createTempSync('transi_migracion');
    final archivo = File('${carpeta.path}/transi.sqlite');
    addTearDown(() {
      if (carpeta.existsSync()) carpeta.deleteSync(recursive: true);
    });

    // Creamos a mano una base con el esquema de la versión 3 (tabla
    // profesionales + columna profesional_id) y un tratamiento con profesional.
    final cruda = sqlite3.open(archivo.path);
    cruda.execute('''
      CREATE TABLE profesionales (
        id TEXT NOT NULL PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        nombre TEXT NOT NULL,
        especialidad TEXT NOT NULL,
        activo INTEGER NOT NULL DEFAULT 1,
        pendiente INTEGER NOT NULL DEFAULT 1,
        creado_en INTEGER NOT NULL DEFAULT 0
      );
    ''');
    cruda.execute('''
      CREATE TABLE tratamientos (
        id TEXT NOT NULL PRIMARY KEY,
        usuario_id TEXT NOT NULL,
        nombre TEXT NOT NULL,
        dosis TEXT NOT NULL,
        frecuencia TEXT NOT NULL,
        fecha_inicio INTEGER NOT NULL,
        fecha_fin INTEGER,
        profesional_id TEXT,
        via TEXT,
        presentacion TEXT,
        dosis_cantidad REAL,
        dosis_unidad TEXT,
        indicacion TEXT,
        activo INTEGER NOT NULL DEFAULT 1,
        pendiente INTEGER NOT NULL DEFAULT 1,
        creado_en INTEGER NOT NULL DEFAULT 0
      );
    ''');
    cruda.execute(
        "INSERT INTO profesionales VALUES ('p1','u1','Dra. García','Endocrinología',1,0,0)");
    cruda.execute(
        "INSERT INTO tratamientos (id,usuario_id,nombre,dosis,frecuencia,fecha_inicio,profesional_id) "
        "VALUES ('t1','u1','Estradiol','2 mg','cada día',0,'p1')");
    cruda.execute('PRAGMA user_version = 3');
    cruda.close();

    // Abrir con el esquema actual dispara la migración v3 → v4.
    final base = BaseLocal(NativeDatabase(archivo));
    addTearDown(base.close);

    final t = (await TratamientoRepositorio(base).observar('u1').first).single;
    expect(t.nombre, 'Estradiol');
    expect(t.profesionalNombre, 'Dra. García');
    expect(t.profesionalEspecialidad, 'Endocrinología');
  });
}
