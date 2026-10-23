import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'base_local.g.dart';

/// Tratamiento, guardado en el teléfono. `fechaFin` nulo = activo.
///
/// `nombre`, `dosis` y `frecuencia` siguen siendo texto obligatorio (R6).
/// Los campos nuevos son opcionales (nullable) para no romper datos existentes.
/// El profesional que lo indicó vive acá (texto), sin entidad aparte.
@DataClassName('FilaTratamiento')
class Tratamientos extends Table {
  TextColumn get id => text()();
  TextColumn get usuarioId => text()();
  TextColumn get nombre => text()();
  TextColumn get dosis => text()();
  TextColumn get frecuencia => text()();
  DateTimeColumn get fechaInicio => dateTime()();
  DateTimeColumn get fechaFin => dateTime().nullable()();
  TextColumn get via => text().nullable()();
  TextColumn get presentacion => text().nullable()();
  RealColumn get dosisCantidad => real().nullable()();
  TextColumn get dosisUnidad => text().nullable()();
  TextColumn get indicacion => text().nullable()();
  TextColumn get profesionalNombre => text().nullable()();
  TextColumn get profesionalEspecialidad => text().nullable()();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  BoolColumn get pendiente => boolean().withDefault(const Constant(true))();
  /// Horas de recordatorio diario, como texto "08:00,20:00" (null = sin aviso).
  TextColumn get recordatorioHoras => text().nullable()();
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
@DriftDatabase(tables: [Tratamientos, Cambios, Adjuntos, Ajustes])
class BaseLocal extends _$BaseLocal {
  BaseLocal([QueryExecutor? ejecutor]) : super(ejecutor ?? _abrir());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, desde, hasta) async {
          if (desde < 2) {
            await customStatement(
                'ALTER TABLE profesionales ADD COLUMN pendiente INTEGER NOT NULL DEFAULT 1');
            await m.addColumn(tratamientos, tratamientos.pendiente);
            await m.addColumn(cambios, cambios.pendiente);
          }
          if (desde < 3) {
            await m.addColumn(tratamientos, tratamientos.via);
            await m.addColumn(tratamientos, tratamientos.presentacion);
            await m.addColumn(tratamientos, tratamientos.dosisCantidad);
            await m.addColumn(tratamientos, tratamientos.dosisUnidad);
            await m.addColumn(tratamientos, tratamientos.indicacion);
          }
          if (desde < 4) {
            await m.addColumn(tratamientos, tratamientos.profesionalNombre);
            await m.addColumn(
                tratamientos, tratamientos.profesionalEspecialidad);
            // Copiar los profesionales ya cargados a cada tratamiento antes de
            // eliminar la tabla (los datos no se pierden).
            await customStatement('''
              UPDATE tratamientos
              SET profesional_nombre = (
                    SELECT nombre FROM profesionales
                    WHERE id = tratamientos.profesional_id),
                  profesional_especialidad = (
                    SELECT especialidad FROM profesionales
                    WHERE id = tratamientos.profesional_id)
              WHERE profesional_id IS NOT NULL
            ''');
            await m.deleteTable('profesionales');
          }
          if (desde < 5) {
            await m.addColumn(tratamientos, tratamientos.recordatorioHoras);
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
