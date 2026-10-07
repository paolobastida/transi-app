import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'base_local.g.dart';

/// Ficha del equipo médico, guardada en el teléfono.
@DataClassName('FilaProfesional')
class Profesionales extends Table {
  TextColumn get id => text()();
  TextColumn get usuarioId => text()();
  TextColumn get nombre => text()();
  TextColumn get especialidad => text()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tratamiento, guardado en el teléfono. `fechaFin` nulo = activo.
@DataClassName('FilaTratamiento')
class Tratamientos extends Table {
  TextColumn get id => text()();
  TextColumn get usuarioId => text()();
  TextColumn get nombre => text()();
  TextColumn get dosis => text()();
  TextColumn get frecuencia => text()();
  DateTimeColumn get fechaInicio => dateTime()();
  DateTimeColumn get fechaFin => dateTime().nullable()();
  TextColumn get profesionalId => text().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Base de datos local del dispositivo (fuente de verdad para la interfaz).
@DriftDatabase(tables: [Profesionales, Tratamientos])
class BaseLocal extends _$BaseLocal {
  BaseLocal([QueryExecutor? ejecutor]) : super(ejecutor ?? _abrir());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _abrir() {
    return driftDatabase(
      name: 'transi',
      native: const DriftNativeOptions(),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }
}
