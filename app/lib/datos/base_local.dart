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
  BoolColumn get pendiente => boolean().withDefault(const Constant(true))();
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
  BoolColumn get pendiente => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cambio (hecho físico) guardado en el teléfono.
@DataClassName('FilaCambio')
class Cambios extends Table {
  TextColumn get id => text()();
  TextColumn get usuarioId => text()();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get descripcion => text().withDefault(const Constant(''))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  BoolColumn get pendiente => boolean().withDefault(const Constant(true))();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Adjunto de un cambio. En el teléfono guardamos el contenido (bytes) en la
/// propia base, para que funcione igual en todas las plataformas.
@DataClassName('FilaAdjunto')
class Adjuntos extends Table {
  TextColumn get id => text()();
  TextColumn get cambioId => text().references(Cambios, #id)();
  TextColumn get tipo => text()();
  TextColumn get nombre => text().withDefault(const Constant(''))();
  BlobColumn get contenido => blob()();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Ajustes simples (clave/valor): por ejemplo, cuándo fue el último respaldo.
@DataClassName('FilaAjuste')
class Ajustes extends Table {
  TextColumn get clave => text()();
  TextColumn get valor => text()();

  @override
  Set<Column> get primaryKey => {clave};
}

/// Base de datos local del dispositivo (fuente de verdad para la interfaz).
@DriftDatabase(tables: [Profesionales, Tratamientos, Cambios, Adjuntos, Ajustes])
class BaseLocal extends _$BaseLocal {
  BaseLocal([QueryExecutor? ejecutor]) : super(ejecutor ?? _abrir());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, desde, hasta) async {
          if (desde < 2) {
            await m.addColumn(profesionales, profesionales.pendiente);
            await m.addColumn(tratamientos, tratamientos.pendiente);
            await m.addColumn(cambios, cambios.pendiente);
          }
        },
      );

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
