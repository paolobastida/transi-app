// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_local.dart';

// ignore_for_file: type=lint
class $TratamientosTable extends Tratamientos
    with TableInfo<$TratamientosTable, FilaTratamiento> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TratamientosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usuarioIdMeta = const VerificationMeta(
    'usuarioId',
  );
  @override
  late final GeneratedColumn<String> usuarioId = GeneratedColumn<String>(
    'usuario_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dosisMeta = const VerificationMeta('dosis');
  @override
  late final GeneratedColumn<String> dosis = GeneratedColumn<String>(
    'dosis',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frecuenciaMeta = const VerificationMeta(
    'frecuencia',
  );
  @override
  late final GeneratedColumn<String> frecuencia = GeneratedColumn<String>(
    'frecuencia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaInicioMeta = const VerificationMeta(
    'fechaInicio',
  );
  @override
  late final GeneratedColumn<DateTime> fechaInicio = GeneratedColumn<DateTime>(
    'fecha_inicio',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaFinMeta = const VerificationMeta(
    'fechaFin',
  );
  @override
  late final GeneratedColumn<DateTime> fechaFin = GeneratedColumn<DateTime>(
    'fecha_fin',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _viaMeta = const VerificationMeta('via');
  @override
  late final GeneratedColumn<String> via = GeneratedColumn<String>(
    'via',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _presentacionMeta = const VerificationMeta(
    'presentacion',
  );
  @override
  late final GeneratedColumn<String> presentacion = GeneratedColumn<String>(
    'presentacion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dosisCantidadMeta = const VerificationMeta(
    'dosisCantidad',
  );
  @override
  late final GeneratedColumn<double> dosisCantidad = GeneratedColumn<double>(
    'dosis_cantidad',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dosisUnidadMeta = const VerificationMeta(
    'dosisUnidad',
  );
  @override
  late final GeneratedColumn<String> dosisUnidad = GeneratedColumn<String>(
    'dosis_unidad',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _indicacionMeta = const VerificationMeta(
    'indicacion',
  );
  @override
  late final GeneratedColumn<String> indicacion = GeneratedColumn<String>(
    'indicacion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profesionalNombreMeta = const VerificationMeta(
    'profesionalNombre',
  );
  @override
  late final GeneratedColumn<String> profesionalNombre =
      GeneratedColumn<String>(
        'profesional_nombre',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _profesionalEspecialidadMeta =
      const VerificationMeta('profesionalEspecialidad');
  @override
  late final GeneratedColumn<String> profesionalEspecialidad =
      GeneratedColumn<String>(
        'profesional_especialidad',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _pendienteMeta = const VerificationMeta(
    'pendiente',
  );
  @override
  late final GeneratedColumn<bool> pendiente = GeneratedColumn<bool>(
    'pendiente',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pendiente" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _recordatorioHorasMeta = const VerificationMeta(
    'recordatorioHoras',
  );
  @override
  late final GeneratedColumn<String> recordatorioHoras =
      GeneratedColumn<String>(
        'recordatorio_horas',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    usuarioId,
    nombre,
    dosis,
    frecuencia,
    fechaInicio,
    fechaFin,
    via,
    presentacion,
    dosisCantidad,
    dosisUnidad,
    indicacion,
    profesionalNombre,
    profesionalEspecialidad,
    activo,
    pendiente,
    recordatorioHoras,
    creadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tratamientos';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaTratamiento> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('usuario_id')) {
      context.handle(
        _usuarioIdMeta,
        usuarioId.isAcceptableOrUnknown(data['usuario_id']!, _usuarioIdMeta),
      );
    } else if (isInserting) {
      context.missing(_usuarioIdMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('dosis')) {
      context.handle(
        _dosisMeta,
        dosis.isAcceptableOrUnknown(data['dosis']!, _dosisMeta),
      );
    } else if (isInserting) {
      context.missing(_dosisMeta);
    }
    if (data.containsKey('frecuencia')) {
      context.handle(
        _frecuenciaMeta,
        frecuencia.isAcceptableOrUnknown(data['frecuencia']!, _frecuenciaMeta),
      );
    } else if (isInserting) {
      context.missing(_frecuenciaMeta);
    }
    if (data.containsKey('fecha_inicio')) {
      context.handle(
        _fechaInicioMeta,
        fechaInicio.isAcceptableOrUnknown(
          data['fecha_inicio']!,
          _fechaInicioMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaInicioMeta);
    }
    if (data.containsKey('fecha_fin')) {
      context.handle(
        _fechaFinMeta,
        fechaFin.isAcceptableOrUnknown(data['fecha_fin']!, _fechaFinMeta),
      );
    }
    if (data.containsKey('via')) {
      context.handle(
        _viaMeta,
        via.isAcceptableOrUnknown(data['via']!, _viaMeta),
      );
    }
    if (data.containsKey('presentacion')) {
      context.handle(
        _presentacionMeta,
        presentacion.isAcceptableOrUnknown(
          data['presentacion']!,
          _presentacionMeta,
        ),
      );
    }
    if (data.containsKey('dosis_cantidad')) {
      context.handle(
        _dosisCantidadMeta,
        dosisCantidad.isAcceptableOrUnknown(
          data['dosis_cantidad']!,
          _dosisCantidadMeta,
        ),
      );
    }
    if (data.containsKey('dosis_unidad')) {
      context.handle(
        _dosisUnidadMeta,
        dosisUnidad.isAcceptableOrUnknown(
          data['dosis_unidad']!,
          _dosisUnidadMeta,
        ),
      );
    }
    if (data.containsKey('indicacion')) {
      context.handle(
        _indicacionMeta,
        indicacion.isAcceptableOrUnknown(data['indicacion']!, _indicacionMeta),
      );
    }
    if (data.containsKey('profesional_nombre')) {
      context.handle(
        _profesionalNombreMeta,
        profesionalNombre.isAcceptableOrUnknown(
          data['profesional_nombre']!,
          _profesionalNombreMeta,
        ),
      );
    }
    if (data.containsKey('profesional_especialidad')) {
      context.handle(
        _profesionalEspecialidadMeta,
        profesionalEspecialidad.isAcceptableOrUnknown(
          data['profesional_especialidad']!,
          _profesionalEspecialidadMeta,
        ),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    if (data.containsKey('pendiente')) {
      context.handle(
        _pendienteMeta,
        pendiente.isAcceptableOrUnknown(data['pendiente']!, _pendienteMeta),
      );
    }
    if (data.containsKey('recordatorio_horas')) {
      context.handle(
        _recordatorioHorasMeta,
        recordatorioHoras.isAcceptableOrUnknown(
          data['recordatorio_horas']!,
          _recordatorioHorasMeta,
        ),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaTratamiento map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaTratamiento(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      usuarioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario_id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      dosis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dosis'],
      )!,
      frecuencia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frecuencia'],
      )!,
      fechaInicio: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_inicio'],
      )!,
      fechaFin: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_fin'],
      ),
      via: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}via'],
      ),
      presentacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}presentacion'],
      ),
      dosisCantidad: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dosis_cantidad'],
      ),
      dosisUnidad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dosis_unidad'],
      ),
      indicacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}indicacion'],
      ),
      profesionalNombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profesional_nombre'],
      ),
      profesionalEspecialidad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profesional_especialidad'],
      ),
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      pendiente: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pendiente'],
      )!,
      recordatorioHoras: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recordatorio_horas'],
      ),
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
    );
  }

  @override
  $TratamientosTable createAlias(String alias) {
    return $TratamientosTable(attachedDatabase, alias);
  }
}

class FilaTratamiento extends DataClass implements Insertable<FilaTratamiento> {
  final String id;
  final String usuarioId;
  final String nombre;
  final String dosis;
  final String frecuencia;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String? via;
  final String? presentacion;
  final double? dosisCantidad;
  final String? dosisUnidad;
  final String? indicacion;
  final String? profesionalNombre;
  final String? profesionalEspecialidad;
  final bool activo;
  final bool pendiente;

  /// Horas de recordatorio diario, como texto "08:00,20:00" (null = sin aviso).
  final String? recordatorioHoras;
  final DateTime creadoEn;
  const FilaTratamiento({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.dosis,
    required this.frecuencia,
    required this.fechaInicio,
    this.fechaFin,
    this.via,
    this.presentacion,
    this.dosisCantidad,
    this.dosisUnidad,
    this.indicacion,
    this.profesionalNombre,
    this.profesionalEspecialidad,
    required this.activo,
    required this.pendiente,
    this.recordatorioHoras,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['usuario_id'] = Variable<String>(usuarioId);
    map['nombre'] = Variable<String>(nombre);
    map['dosis'] = Variable<String>(dosis);
    map['frecuencia'] = Variable<String>(frecuencia);
    map['fecha_inicio'] = Variable<DateTime>(fechaInicio);
    if (!nullToAbsent || fechaFin != null) {
      map['fecha_fin'] = Variable<DateTime>(fechaFin);
    }
    if (!nullToAbsent || via != null) {
      map['via'] = Variable<String>(via);
    }
    if (!nullToAbsent || presentacion != null) {
      map['presentacion'] = Variable<String>(presentacion);
    }
    if (!nullToAbsent || dosisCantidad != null) {
      map['dosis_cantidad'] = Variable<double>(dosisCantidad);
    }
    if (!nullToAbsent || dosisUnidad != null) {
      map['dosis_unidad'] = Variable<String>(dosisUnidad);
    }
    if (!nullToAbsent || indicacion != null) {
      map['indicacion'] = Variable<String>(indicacion);
    }
    if (!nullToAbsent || profesionalNombre != null) {
      map['profesional_nombre'] = Variable<String>(profesionalNombre);
    }
    if (!nullToAbsent || profesionalEspecialidad != null) {
      map['profesional_especialidad'] = Variable<String>(
        profesionalEspecialidad,
      );
    }
    map['activo'] = Variable<bool>(activo);
    map['pendiente'] = Variable<bool>(pendiente);
    if (!nullToAbsent || recordatorioHoras != null) {
      map['recordatorio_horas'] = Variable<String>(recordatorioHoras);
    }
    map['creado_en'] = Variable<DateTime>(creadoEn);
    return map;
  }

  TratamientosCompanion toCompanion(bool nullToAbsent) {
    return TratamientosCompanion(
      id: Value(id),
      usuarioId: Value(usuarioId),
      nombre: Value(nombre),
      dosis: Value(dosis),
      frecuencia: Value(frecuencia),
      fechaInicio: Value(fechaInicio),
      fechaFin: fechaFin == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaFin),
      via: via == null && nullToAbsent ? const Value.absent() : Value(via),
      presentacion: presentacion == null && nullToAbsent
          ? const Value.absent()
          : Value(presentacion),
      dosisCantidad: dosisCantidad == null && nullToAbsent
          ? const Value.absent()
          : Value(dosisCantidad),
      dosisUnidad: dosisUnidad == null && nullToAbsent
          ? const Value.absent()
          : Value(dosisUnidad),
      indicacion: indicacion == null && nullToAbsent
          ? const Value.absent()
          : Value(indicacion),
      profesionalNombre: profesionalNombre == null && nullToAbsent
          ? const Value.absent()
          : Value(profesionalNombre),
      profesionalEspecialidad: profesionalEspecialidad == null && nullToAbsent
          ? const Value.absent()
          : Value(profesionalEspecialidad),
      activo: Value(activo),
      pendiente: Value(pendiente),
      recordatorioHoras: recordatorioHoras == null && nullToAbsent
          ? const Value.absent()
          : Value(recordatorioHoras),
      creadoEn: Value(creadoEn),
    );
  }

  factory FilaTratamiento.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaTratamiento(
      id: serializer.fromJson<String>(json['id']),
      usuarioId: serializer.fromJson<String>(json['usuarioId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      dosis: serializer.fromJson<String>(json['dosis']),
      frecuencia: serializer.fromJson<String>(json['frecuencia']),
      fechaInicio: serializer.fromJson<DateTime>(json['fechaInicio']),
      fechaFin: serializer.fromJson<DateTime?>(json['fechaFin']),
      via: serializer.fromJson<String?>(json['via']),
      presentacion: serializer.fromJson<String?>(json['presentacion']),
      dosisCantidad: serializer.fromJson<double?>(json['dosisCantidad']),
      dosisUnidad: serializer.fromJson<String?>(json['dosisUnidad']),
      indicacion: serializer.fromJson<String?>(json['indicacion']),
      profesionalNombre: serializer.fromJson<String?>(
        json['profesionalNombre'],
      ),
      profesionalEspecialidad: serializer.fromJson<String?>(
        json['profesionalEspecialidad'],
      ),
      activo: serializer.fromJson<bool>(json['activo']),
      pendiente: serializer.fromJson<bool>(json['pendiente']),
      recordatorioHoras: serializer.fromJson<String?>(
        json['recordatorioHoras'],
      ),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'usuarioId': serializer.toJson<String>(usuarioId),
      'nombre': serializer.toJson<String>(nombre),
      'dosis': serializer.toJson<String>(dosis),
      'frecuencia': serializer.toJson<String>(frecuencia),
      'fechaInicio': serializer.toJson<DateTime>(fechaInicio),
      'fechaFin': serializer.toJson<DateTime?>(fechaFin),
      'via': serializer.toJson<String?>(via),
      'presentacion': serializer.toJson<String?>(presentacion),
      'dosisCantidad': serializer.toJson<double?>(dosisCantidad),
      'dosisUnidad': serializer.toJson<String?>(dosisUnidad),
      'indicacion': serializer.toJson<String?>(indicacion),
      'profesionalNombre': serializer.toJson<String?>(profesionalNombre),
      'profesionalEspecialidad': serializer.toJson<String?>(
        profesionalEspecialidad,
      ),
      'activo': serializer.toJson<bool>(activo),
      'pendiente': serializer.toJson<bool>(pendiente),
      'recordatorioHoras': serializer.toJson<String?>(recordatorioHoras),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  FilaTratamiento copyWith({
    String? id,
    String? usuarioId,
    String? nombre,
    String? dosis,
    String? frecuencia,
    DateTime? fechaInicio,
    Value<DateTime?> fechaFin = const Value.absent(),
    Value<String?> via = const Value.absent(),
    Value<String?> presentacion = const Value.absent(),
    Value<double?> dosisCantidad = const Value.absent(),
    Value<String?> dosisUnidad = const Value.absent(),
    Value<String?> indicacion = const Value.absent(),
    Value<String?> profesionalNombre = const Value.absent(),
    Value<String?> profesionalEspecialidad = const Value.absent(),
    bool? activo,
    bool? pendiente,
    Value<String?> recordatorioHoras = const Value.absent(),
    DateTime? creadoEn,
  }) => FilaTratamiento(
    id: id ?? this.id,
    usuarioId: usuarioId ?? this.usuarioId,
    nombre: nombre ?? this.nombre,
    dosis: dosis ?? this.dosis,
    frecuencia: frecuencia ?? this.frecuencia,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin.present ? fechaFin.value : this.fechaFin,
    via: via.present ? via.value : this.via,
    presentacion: presentacion.present ? presentacion.value : this.presentacion,
    dosisCantidad: dosisCantidad.present
        ? dosisCantidad.value
        : this.dosisCantidad,
    dosisUnidad: dosisUnidad.present ? dosisUnidad.value : this.dosisUnidad,
    indicacion: indicacion.present ? indicacion.value : this.indicacion,
    profesionalNombre: profesionalNombre.present
        ? profesionalNombre.value
        : this.profesionalNombre,
    profesionalEspecialidad: profesionalEspecialidad.present
        ? profesionalEspecialidad.value
        : this.profesionalEspecialidad,
    activo: activo ?? this.activo,
    pendiente: pendiente ?? this.pendiente,
    recordatorioHoras: recordatorioHoras.present
        ? recordatorioHoras.value
        : this.recordatorioHoras,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  FilaTratamiento copyWithCompanion(TratamientosCompanion data) {
    return FilaTratamiento(
      id: data.id.present ? data.id.value : this.id,
      usuarioId: data.usuarioId.present ? data.usuarioId.value : this.usuarioId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      dosis: data.dosis.present ? data.dosis.value : this.dosis,
      frecuencia: data.frecuencia.present
          ? data.frecuencia.value
          : this.frecuencia,
      fechaInicio: data.fechaInicio.present
          ? data.fechaInicio.value
          : this.fechaInicio,
      fechaFin: data.fechaFin.present ? data.fechaFin.value : this.fechaFin,
      via: data.via.present ? data.via.value : this.via,
      presentacion: data.presentacion.present
          ? data.presentacion.value
          : this.presentacion,
      dosisCantidad: data.dosisCantidad.present
          ? data.dosisCantidad.value
          : this.dosisCantidad,
      dosisUnidad: data.dosisUnidad.present
          ? data.dosisUnidad.value
          : this.dosisUnidad,
      indicacion: data.indicacion.present
          ? data.indicacion.value
          : this.indicacion,
      profesionalNombre: data.profesionalNombre.present
          ? data.profesionalNombre.value
          : this.profesionalNombre,
      profesionalEspecialidad: data.profesionalEspecialidad.present
          ? data.profesionalEspecialidad.value
          : this.profesionalEspecialidad,
      activo: data.activo.present ? data.activo.value : this.activo,
      pendiente: data.pendiente.present ? data.pendiente.value : this.pendiente,
      recordatorioHoras: data.recordatorioHoras.present
          ? data.recordatorioHoras.value
          : this.recordatorioHoras,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaTratamiento(')
          ..write('id: $id, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('nombre: $nombre, ')
          ..write('dosis: $dosis, ')
          ..write('frecuencia: $frecuencia, ')
          ..write('fechaInicio: $fechaInicio, ')
          ..write('fechaFin: $fechaFin, ')
          ..write('via: $via, ')
          ..write('presentacion: $presentacion, ')
          ..write('dosisCantidad: $dosisCantidad, ')
          ..write('dosisUnidad: $dosisUnidad, ')
          ..write('indicacion: $indicacion, ')
          ..write('profesionalNombre: $profesionalNombre, ')
          ..write('profesionalEspecialidad: $profesionalEspecialidad, ')
          ..write('activo: $activo, ')
          ..write('pendiente: $pendiente, ')
          ..write('recordatorioHoras: $recordatorioHoras, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    usuarioId,
    nombre,
    dosis,
    frecuencia,
    fechaInicio,
    fechaFin,
    via,
    presentacion,
    dosisCantidad,
    dosisUnidad,
    indicacion,
    profesionalNombre,
    profesionalEspecialidad,
    activo,
    pendiente,
    recordatorioHoras,
    creadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaTratamiento &&
          other.id == this.id &&
          other.usuarioId == this.usuarioId &&
          other.nombre == this.nombre &&
          other.dosis == this.dosis &&
          other.frecuencia == this.frecuencia &&
          other.fechaInicio == this.fechaInicio &&
          other.fechaFin == this.fechaFin &&
          other.via == this.via &&
          other.presentacion == this.presentacion &&
          other.dosisCantidad == this.dosisCantidad &&
          other.dosisUnidad == this.dosisUnidad &&
          other.indicacion == this.indicacion &&
          other.profesionalNombre == this.profesionalNombre &&
          other.profesionalEspecialidad == this.profesionalEspecialidad &&
          other.activo == this.activo &&
          other.pendiente == this.pendiente &&
          other.recordatorioHoras == this.recordatorioHoras &&
          other.creadoEn == this.creadoEn);
}

class TratamientosCompanion extends UpdateCompanion<FilaTratamiento> {
  final Value<String> id;
  final Value<String> usuarioId;
  final Value<String> nombre;
  final Value<String> dosis;
  final Value<String> frecuencia;
  final Value<DateTime> fechaInicio;
  final Value<DateTime?> fechaFin;
  final Value<String?> via;
  final Value<String?> presentacion;
  final Value<double?> dosisCantidad;
  final Value<String?> dosisUnidad;
  final Value<String?> indicacion;
  final Value<String?> profesionalNombre;
  final Value<String?> profesionalEspecialidad;
  final Value<bool> activo;
  final Value<bool> pendiente;
  final Value<String?> recordatorioHoras;
  final Value<DateTime> creadoEn;
  final Value<int> rowid;
  const TratamientosCompanion({
    this.id = const Value.absent(),
    this.usuarioId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.dosis = const Value.absent(),
    this.frecuencia = const Value.absent(),
    this.fechaInicio = const Value.absent(),
    this.fechaFin = const Value.absent(),
    this.via = const Value.absent(),
    this.presentacion = const Value.absent(),
    this.dosisCantidad = const Value.absent(),
    this.dosisUnidad = const Value.absent(),
    this.indicacion = const Value.absent(),
    this.profesionalNombre = const Value.absent(),
    this.profesionalEspecialidad = const Value.absent(),
    this.activo = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.recordatorioHoras = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TratamientosCompanion.insert({
    required String id,
    required String usuarioId,
    required String nombre,
    required String dosis,
    required String frecuencia,
    required DateTime fechaInicio,
    this.fechaFin = const Value.absent(),
    this.via = const Value.absent(),
    this.presentacion = const Value.absent(),
    this.dosisCantidad = const Value.absent(),
    this.dosisUnidad = const Value.absent(),
    this.indicacion = const Value.absent(),
    this.profesionalNombre = const Value.absent(),
    this.profesionalEspecialidad = const Value.absent(),
    this.activo = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.recordatorioHoras = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       usuarioId = Value(usuarioId),
       nombre = Value(nombre),
       dosis = Value(dosis),
       frecuencia = Value(frecuencia),
       fechaInicio = Value(fechaInicio);
  static Insertable<FilaTratamiento> custom({
    Expression<String>? id,
    Expression<String>? usuarioId,
    Expression<String>? nombre,
    Expression<String>? dosis,
    Expression<String>? frecuencia,
    Expression<DateTime>? fechaInicio,
    Expression<DateTime>? fechaFin,
    Expression<String>? via,
    Expression<String>? presentacion,
    Expression<double>? dosisCantidad,
    Expression<String>? dosisUnidad,
    Expression<String>? indicacion,
    Expression<String>? profesionalNombre,
    Expression<String>? profesionalEspecialidad,
    Expression<bool>? activo,
    Expression<bool>? pendiente,
    Expression<String>? recordatorioHoras,
    Expression<DateTime>? creadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (usuarioId != null) 'usuario_id': usuarioId,
      if (nombre != null) 'nombre': nombre,
      if (dosis != null) 'dosis': dosis,
      if (frecuencia != null) 'frecuencia': frecuencia,
      if (fechaInicio != null) 'fecha_inicio': fechaInicio,
      if (fechaFin != null) 'fecha_fin': fechaFin,
      if (via != null) 'via': via,
      if (presentacion != null) 'presentacion': presentacion,
      if (dosisCantidad != null) 'dosis_cantidad': dosisCantidad,
      if (dosisUnidad != null) 'dosis_unidad': dosisUnidad,
      if (indicacion != null) 'indicacion': indicacion,
      if (profesionalNombre != null) 'profesional_nombre': profesionalNombre,
      if (profesionalEspecialidad != null)
        'profesional_especialidad': profesionalEspecialidad,
      if (activo != null) 'activo': activo,
      if (pendiente != null) 'pendiente': pendiente,
      if (recordatorioHoras != null) 'recordatorio_horas': recordatorioHoras,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TratamientosCompanion copyWith({
    Value<String>? id,
    Value<String>? usuarioId,
    Value<String>? nombre,
    Value<String>? dosis,
    Value<String>? frecuencia,
    Value<DateTime>? fechaInicio,
    Value<DateTime?>? fechaFin,
    Value<String?>? via,
    Value<String?>? presentacion,
    Value<double?>? dosisCantidad,
    Value<String?>? dosisUnidad,
    Value<String?>? indicacion,
    Value<String?>? profesionalNombre,
    Value<String?>? profesionalEspecialidad,
    Value<bool>? activo,
    Value<bool>? pendiente,
    Value<String?>? recordatorioHoras,
    Value<DateTime>? creadoEn,
    Value<int>? rowid,
  }) {
    return TratamientosCompanion(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      nombre: nombre ?? this.nombre,
      dosis: dosis ?? this.dosis,
      frecuencia: frecuencia ?? this.frecuencia,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      via: via ?? this.via,
      presentacion: presentacion ?? this.presentacion,
      dosisCantidad: dosisCantidad ?? this.dosisCantidad,
      dosisUnidad: dosisUnidad ?? this.dosisUnidad,
      indicacion: indicacion ?? this.indicacion,
      profesionalNombre: profesionalNombre ?? this.profesionalNombre,
      profesionalEspecialidad:
          profesionalEspecialidad ?? this.profesionalEspecialidad,
      activo: activo ?? this.activo,
      pendiente: pendiente ?? this.pendiente,
      recordatorioHoras: recordatorioHoras ?? this.recordatorioHoras,
      creadoEn: creadoEn ?? this.creadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (usuarioId.present) {
      map['usuario_id'] = Variable<String>(usuarioId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (dosis.present) {
      map['dosis'] = Variable<String>(dosis.value);
    }
    if (frecuencia.present) {
      map['frecuencia'] = Variable<String>(frecuencia.value);
    }
    if (fechaInicio.present) {
      map['fecha_inicio'] = Variable<DateTime>(fechaInicio.value);
    }
    if (fechaFin.present) {
      map['fecha_fin'] = Variable<DateTime>(fechaFin.value);
    }
    if (via.present) {
      map['via'] = Variable<String>(via.value);
    }
    if (presentacion.present) {
      map['presentacion'] = Variable<String>(presentacion.value);
    }
    if (dosisCantidad.present) {
      map['dosis_cantidad'] = Variable<double>(dosisCantidad.value);
    }
    if (dosisUnidad.present) {
      map['dosis_unidad'] = Variable<String>(dosisUnidad.value);
    }
    if (indicacion.present) {
      map['indicacion'] = Variable<String>(indicacion.value);
    }
    if (profesionalNombre.present) {
      map['profesional_nombre'] = Variable<String>(profesionalNombre.value);
    }
    if (profesionalEspecialidad.present) {
      map['profesional_especialidad'] = Variable<String>(
        profesionalEspecialidad.value,
      );
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (pendiente.present) {
      map['pendiente'] = Variable<bool>(pendiente.value);
    }
    if (recordatorioHoras.present) {
      map['recordatorio_horas'] = Variable<String>(recordatorioHoras.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TratamientosCompanion(')
          ..write('id: $id, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('nombre: $nombre, ')
          ..write('dosis: $dosis, ')
          ..write('frecuencia: $frecuencia, ')
          ..write('fechaInicio: $fechaInicio, ')
          ..write('fechaFin: $fechaFin, ')
          ..write('via: $via, ')
          ..write('presentacion: $presentacion, ')
          ..write('dosisCantidad: $dosisCantidad, ')
          ..write('dosisUnidad: $dosisUnidad, ')
          ..write('indicacion: $indicacion, ')
          ..write('profesionalNombre: $profesionalNombre, ')
          ..write('profesionalEspecialidad: $profesionalEspecialidad, ')
          ..write('activo: $activo, ')
          ..write('pendiente: $pendiente, ')
          ..write('recordatorioHoras: $recordatorioHoras, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CambiosTable extends Cambios with TableInfo<$CambiosTable, FilaCambio> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CambiosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usuarioIdMeta = const VerificationMeta(
    'usuarioId',
  );
  @override
  late final GeneratedColumn<String> usuarioId = GeneratedColumn<String>(
    'usuario_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descripcionMeta = const VerificationMeta(
    'descripcion',
  );
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _pendienteMeta = const VerificationMeta(
    'pendiente',
  );
  @override
  late final GeneratedColumn<bool> pendiente = GeneratedColumn<bool>(
    'pendiente',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pendiente" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    usuarioId,
    fecha,
    descripcion,
    activo,
    pendiente,
    creadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cambios';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaCambio> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('usuario_id')) {
      context.handle(
        _usuarioIdMeta,
        usuarioId.isAcceptableOrUnknown(data['usuario_id']!, _usuarioIdMeta),
      );
    } else if (isInserting) {
      context.missing(_usuarioIdMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('descripcion')) {
      context.handle(
        _descripcionMeta,
        descripcion.isAcceptableOrUnknown(
          data['descripcion']!,
          _descripcionMeta,
        ),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    if (data.containsKey('pendiente')) {
      context.handle(
        _pendienteMeta,
        pendiente.isAcceptableOrUnknown(data['pendiente']!, _pendienteMeta),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaCambio map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaCambio(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      usuarioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario_id'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      descripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      pendiente: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pendiente'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
    );
  }

  @override
  $CambiosTable createAlias(String alias) {
    return $CambiosTable(attachedDatabase, alias);
  }
}

class FilaCambio extends DataClass implements Insertable<FilaCambio> {
  final String id;
  final String usuarioId;
  final DateTime fecha;
  final String descripcion;
  final bool activo;
  final bool pendiente;
  final DateTime creadoEn;
  const FilaCambio({
    required this.id,
    required this.usuarioId,
    required this.fecha,
    required this.descripcion,
    required this.activo,
    required this.pendiente,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['usuario_id'] = Variable<String>(usuarioId);
    map['fecha'] = Variable<DateTime>(fecha);
    map['descripcion'] = Variable<String>(descripcion);
    map['activo'] = Variable<bool>(activo);
    map['pendiente'] = Variable<bool>(pendiente);
    map['creado_en'] = Variable<DateTime>(creadoEn);
    return map;
  }

  CambiosCompanion toCompanion(bool nullToAbsent) {
    return CambiosCompanion(
      id: Value(id),
      usuarioId: Value(usuarioId),
      fecha: Value(fecha),
      descripcion: Value(descripcion),
      activo: Value(activo),
      pendiente: Value(pendiente),
      creadoEn: Value(creadoEn),
    );
  }

  factory FilaCambio.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaCambio(
      id: serializer.fromJson<String>(json['id']),
      usuarioId: serializer.fromJson<String>(json['usuarioId']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      descripcion: serializer.fromJson<String>(json['descripcion']),
      activo: serializer.fromJson<bool>(json['activo']),
      pendiente: serializer.fromJson<bool>(json['pendiente']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'usuarioId': serializer.toJson<String>(usuarioId),
      'fecha': serializer.toJson<DateTime>(fecha),
      'descripcion': serializer.toJson<String>(descripcion),
      'activo': serializer.toJson<bool>(activo),
      'pendiente': serializer.toJson<bool>(pendiente),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  FilaCambio copyWith({
    String? id,
    String? usuarioId,
    DateTime? fecha,
    String? descripcion,
    bool? activo,
    bool? pendiente,
    DateTime? creadoEn,
  }) => FilaCambio(
    id: id ?? this.id,
    usuarioId: usuarioId ?? this.usuarioId,
    fecha: fecha ?? this.fecha,
    descripcion: descripcion ?? this.descripcion,
    activo: activo ?? this.activo,
    pendiente: pendiente ?? this.pendiente,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  FilaCambio copyWithCompanion(CambiosCompanion data) {
    return FilaCambio(
      id: data.id.present ? data.id.value : this.id,
      usuarioId: data.usuarioId.present ? data.usuarioId.value : this.usuarioId,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      descripcion: data.descripcion.present
          ? data.descripcion.value
          : this.descripcion,
      activo: data.activo.present ? data.activo.value : this.activo,
      pendiente: data.pendiente.present ? data.pendiente.value : this.pendiente,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaCambio(')
          ..write('id: $id, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('fecha: $fecha, ')
          ..write('descripcion: $descripcion, ')
          ..write('activo: $activo, ')
          ..write('pendiente: $pendiente, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    usuarioId,
    fecha,
    descripcion,
    activo,
    pendiente,
    creadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaCambio &&
          other.id == this.id &&
          other.usuarioId == this.usuarioId &&
          other.fecha == this.fecha &&
          other.descripcion == this.descripcion &&
          other.activo == this.activo &&
          other.pendiente == this.pendiente &&
          other.creadoEn == this.creadoEn);
}

class CambiosCompanion extends UpdateCompanion<FilaCambio> {
  final Value<String> id;
  final Value<String> usuarioId;
  final Value<DateTime> fecha;
  final Value<String> descripcion;
  final Value<bool> activo;
  final Value<bool> pendiente;
  final Value<DateTime> creadoEn;
  final Value<int> rowid;
  const CambiosCompanion({
    this.id = const Value.absent(),
    this.usuarioId = const Value.absent(),
    this.fecha = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.activo = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CambiosCompanion.insert({
    required String id,
    required String usuarioId,
    required DateTime fecha,
    this.descripcion = const Value.absent(),
    this.activo = const Value.absent(),
    this.pendiente = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       usuarioId = Value(usuarioId),
       fecha = Value(fecha);
  static Insertable<FilaCambio> custom({
    Expression<String>? id,
    Expression<String>? usuarioId,
    Expression<DateTime>? fecha,
    Expression<String>? descripcion,
    Expression<bool>? activo,
    Expression<bool>? pendiente,
    Expression<DateTime>? creadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (usuarioId != null) 'usuario_id': usuarioId,
      if (fecha != null) 'fecha': fecha,
      if (descripcion != null) 'descripcion': descripcion,
      if (activo != null) 'activo': activo,
      if (pendiente != null) 'pendiente': pendiente,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CambiosCompanion copyWith({
    Value<String>? id,
    Value<String>? usuarioId,
    Value<DateTime>? fecha,
    Value<String>? descripcion,
    Value<bool>? activo,
    Value<bool>? pendiente,
    Value<DateTime>? creadoEn,
    Value<int>? rowid,
  }) {
    return CambiosCompanion(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      fecha: fecha ?? this.fecha,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
      pendiente: pendiente ?? this.pendiente,
      creadoEn: creadoEn ?? this.creadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (usuarioId.present) {
      map['usuario_id'] = Variable<String>(usuarioId.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (pendiente.present) {
      map['pendiente'] = Variable<bool>(pendiente.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CambiosCompanion(')
          ..write('id: $id, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('fecha: $fecha, ')
          ..write('descripcion: $descripcion, ')
          ..write('activo: $activo, ')
          ..write('pendiente: $pendiente, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdjuntosTable extends Adjuntos
    with TableInfo<$AdjuntosTable, FilaAdjunto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdjuntosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cambioIdMeta = const VerificationMeta(
    'cambioId',
  );
  @override
  late final GeneratedColumn<String> cambioId = GeneratedColumn<String>(
    'cambio_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cambios (id)',
    ),
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contenidoMeta = const VerificationMeta(
    'contenido',
  );
  @override
  late final GeneratedColumn<Uint8List> contenido = GeneratedColumn<Uint8List>(
    'contenido',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cambioId,
    tipo,
    nombre,
    contenido,
    creadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adjuntos';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaAdjunto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cambio_id')) {
      context.handle(
        _cambioIdMeta,
        cambioId.isAcceptableOrUnknown(data['cambio_id']!, _cambioIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cambioIdMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    }
    if (data.containsKey('contenido')) {
      context.handle(
        _contenidoMeta,
        contenido.isAcceptableOrUnknown(data['contenido']!, _contenidoMeta),
      );
    } else if (isInserting) {
      context.missing(_contenidoMeta);
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaAdjunto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaAdjunto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cambioId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cambio_id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      contenido: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}contenido'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
    );
  }

  @override
  $AdjuntosTable createAlias(String alias) {
    return $AdjuntosTable(attachedDatabase, alias);
  }
}

class FilaAdjunto extends DataClass implements Insertable<FilaAdjunto> {
  final String id;
  final String cambioId;
  final String tipo;
  final String nombre;
  final Uint8List contenido;
  final DateTime creadoEn;
  const FilaAdjunto({
    required this.id,
    required this.cambioId,
    required this.tipo,
    required this.nombre,
    required this.contenido,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cambio_id'] = Variable<String>(cambioId);
    map['tipo'] = Variable<String>(tipo);
    map['nombre'] = Variable<String>(nombre);
    map['contenido'] = Variable<Uint8List>(contenido);
    map['creado_en'] = Variable<DateTime>(creadoEn);
    return map;
  }

  AdjuntosCompanion toCompanion(bool nullToAbsent) {
    return AdjuntosCompanion(
      id: Value(id),
      cambioId: Value(cambioId),
      tipo: Value(tipo),
      nombre: Value(nombre),
      contenido: Value(contenido),
      creadoEn: Value(creadoEn),
    );
  }

  factory FilaAdjunto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaAdjunto(
      id: serializer.fromJson<String>(json['id']),
      cambioId: serializer.fromJson<String>(json['cambioId']),
      tipo: serializer.fromJson<String>(json['tipo']),
      nombre: serializer.fromJson<String>(json['nombre']),
      contenido: serializer.fromJson<Uint8List>(json['contenido']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cambioId': serializer.toJson<String>(cambioId),
      'tipo': serializer.toJson<String>(tipo),
      'nombre': serializer.toJson<String>(nombre),
      'contenido': serializer.toJson<Uint8List>(contenido),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  FilaAdjunto copyWith({
    String? id,
    String? cambioId,
    String? tipo,
    String? nombre,
    Uint8List? contenido,
    DateTime? creadoEn,
  }) => FilaAdjunto(
    id: id ?? this.id,
    cambioId: cambioId ?? this.cambioId,
    tipo: tipo ?? this.tipo,
    nombre: nombre ?? this.nombre,
    contenido: contenido ?? this.contenido,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  FilaAdjunto copyWithCompanion(AdjuntosCompanion data) {
    return FilaAdjunto(
      id: data.id.present ? data.id.value : this.id,
      cambioId: data.cambioId.present ? data.cambioId.value : this.cambioId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      contenido: data.contenido.present ? data.contenido.value : this.contenido,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaAdjunto(')
          ..write('id: $id, ')
          ..write('cambioId: $cambioId, ')
          ..write('tipo: $tipo, ')
          ..write('nombre: $nombre, ')
          ..write('contenido: $contenido, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cambioId,
    tipo,
    nombre,
    $driftBlobEquality.hash(contenido),
    creadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaAdjunto &&
          other.id == this.id &&
          other.cambioId == this.cambioId &&
          other.tipo == this.tipo &&
          other.nombre == this.nombre &&
          $driftBlobEquality.equals(other.contenido, this.contenido) &&
          other.creadoEn == this.creadoEn);
}

class AdjuntosCompanion extends UpdateCompanion<FilaAdjunto> {
  final Value<String> id;
  final Value<String> cambioId;
  final Value<String> tipo;
  final Value<String> nombre;
  final Value<Uint8List> contenido;
  final Value<DateTime> creadoEn;
  final Value<int> rowid;
  const AdjuntosCompanion({
    this.id = const Value.absent(),
    this.cambioId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.nombre = const Value.absent(),
    this.contenido = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdjuntosCompanion.insert({
    required String id,
    required String cambioId,
    required String tipo,
    this.nombre = const Value.absent(),
    required Uint8List contenido,
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cambioId = Value(cambioId),
       tipo = Value(tipo),
       contenido = Value(contenido);
  static Insertable<FilaAdjunto> custom({
    Expression<String>? id,
    Expression<String>? cambioId,
    Expression<String>? tipo,
    Expression<String>? nombre,
    Expression<Uint8List>? contenido,
    Expression<DateTime>? creadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cambioId != null) 'cambio_id': cambioId,
      if (tipo != null) 'tipo': tipo,
      if (nombre != null) 'nombre': nombre,
      if (contenido != null) 'contenido': contenido,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdjuntosCompanion copyWith({
    Value<String>? id,
    Value<String>? cambioId,
    Value<String>? tipo,
    Value<String>? nombre,
    Value<Uint8List>? contenido,
    Value<DateTime>? creadoEn,
    Value<int>? rowid,
  }) {
    return AdjuntosCompanion(
      id: id ?? this.id,
      cambioId: cambioId ?? this.cambioId,
      tipo: tipo ?? this.tipo,
      nombre: nombre ?? this.nombre,
      contenido: contenido ?? this.contenido,
      creadoEn: creadoEn ?? this.creadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cambioId.present) {
      map['cambio_id'] = Variable<String>(cambioId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (contenido.present) {
      map['contenido'] = Variable<Uint8List>(contenido.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdjuntosCompanion(')
          ..write('id: $id, ')
          ..write('cambioId: $cambioId, ')
          ..write('tipo: $tipo, ')
          ..write('nombre: $nombre, ')
          ..write('contenido: $contenido, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AjustesTable extends Ajustes with TableInfo<$AjustesTable, FilaAjuste> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AjustesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _claveMeta = const VerificationMeta('clave');
  @override
  late final GeneratedColumn<String> clave = GeneratedColumn<String>(
    'clave',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<String> valor = GeneratedColumn<String>(
    'valor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [clave, valor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ajustes';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaAjuste> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('clave')) {
      context.handle(
        _claveMeta,
        clave.isAcceptableOrUnknown(data['clave']!, _claveMeta),
      );
    } else if (isInserting) {
      context.missing(_claveMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    } else if (isInserting) {
      context.missing(_valorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clave};
  @override
  FilaAjuste map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaAjuste(
      clave: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clave'],
      )!,
      valor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valor'],
      )!,
    );
  }

  @override
  $AjustesTable createAlias(String alias) {
    return $AjustesTable(attachedDatabase, alias);
  }
}

class FilaAjuste extends DataClass implements Insertable<FilaAjuste> {
  final String clave;
  final String valor;
  const FilaAjuste({required this.clave, required this.valor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['clave'] = Variable<String>(clave);
    map['valor'] = Variable<String>(valor);
    return map;
  }

  AjustesCompanion toCompanion(bool nullToAbsent) {
    return AjustesCompanion(clave: Value(clave), valor: Value(valor));
  }

  factory FilaAjuste.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaAjuste(
      clave: serializer.fromJson<String>(json['clave']),
      valor: serializer.fromJson<String>(json['valor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clave': serializer.toJson<String>(clave),
      'valor': serializer.toJson<String>(valor),
    };
  }

  FilaAjuste copyWith({String? clave, String? valor}) =>
      FilaAjuste(clave: clave ?? this.clave, valor: valor ?? this.valor);
  FilaAjuste copyWithCompanion(AjustesCompanion data) {
    return FilaAjuste(
      clave: data.clave.present ? data.clave.value : this.clave,
      valor: data.valor.present ? data.valor.value : this.valor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaAjuste(')
          ..write('clave: $clave, ')
          ..write('valor: $valor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(clave, valor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaAjuste &&
          other.clave == this.clave &&
          other.valor == this.valor);
}

class AjustesCompanion extends UpdateCompanion<FilaAjuste> {
  final Value<String> clave;
  final Value<String> valor;
  final Value<int> rowid;
  const AjustesCompanion({
    this.clave = const Value.absent(),
    this.valor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AjustesCompanion.insert({
    required String clave,
    required String valor,
    this.rowid = const Value.absent(),
  }) : clave = Value(clave),
       valor = Value(valor);
  static Insertable<FilaAjuste> custom({
    Expression<String>? clave,
    Expression<String>? valor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clave != null) 'clave': clave,
      if (valor != null) 'valor': valor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AjustesCompanion copyWith({
    Value<String>? clave,
    Value<String>? valor,
    Value<int>? rowid,
  }) {
    return AjustesCompanion(
      clave: clave ?? this.clave,
      valor: valor ?? this.valor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clave.present) {
      map['clave'] = Variable<String>(clave.value);
    }
    if (valor.present) {
      map['valor'] = Variable<String>(valor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AjustesCompanion(')
          ..write('clave: $clave, ')
          ..write('valor: $valor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$BaseLocal extends GeneratedDatabase {
  _$BaseLocal(QueryExecutor e) : super(e);
  $BaseLocalManager get managers => $BaseLocalManager(this);
  late final $TratamientosTable tratamientos = $TratamientosTable(this);
  late final $CambiosTable cambios = $CambiosTable(this);
  late final $AdjuntosTable adjuntos = $AdjuntosTable(this);
  late final $AjustesTable ajustes = $AjustesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tratamientos,
    cambios,
    adjuntos,
    ajustes,
  ];
}

typedef $$TratamientosTableCreateCompanionBuilder =
    TratamientosCompanion Function({
      required String id,
      required String usuarioId,
      required String nombre,
      required String dosis,
      required String frecuencia,
      required DateTime fechaInicio,
      Value<DateTime?> fechaFin,
      Value<String?> via,
      Value<String?> presentacion,
      Value<double?> dosisCantidad,
      Value<String?> dosisUnidad,
      Value<String?> indicacion,
      Value<String?> profesionalNombre,
      Value<String?> profesionalEspecialidad,
      Value<bool> activo,
      Value<bool> pendiente,
      Value<String?> recordatorioHoras,
      Value<DateTime> creadoEn,
      Value<int> rowid,
    });
typedef $$TratamientosTableUpdateCompanionBuilder =
    TratamientosCompanion Function({
      Value<String> id,
      Value<String> usuarioId,
      Value<String> nombre,
      Value<String> dosis,
      Value<String> frecuencia,
      Value<DateTime> fechaInicio,
      Value<DateTime?> fechaFin,
      Value<String?> via,
      Value<String?> presentacion,
      Value<double?> dosisCantidad,
      Value<String?> dosisUnidad,
      Value<String?> indicacion,
      Value<String?> profesionalNombre,
      Value<String?> profesionalEspecialidad,
      Value<bool> activo,
      Value<bool> pendiente,
      Value<String?> recordatorioHoras,
      Value<DateTime> creadoEn,
      Value<int> rowid,
    });

class $$TratamientosTableFilterComposer
    extends Composer<_$BaseLocal, $TratamientosTable> {
  $$TratamientosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usuarioId => $composableBuilder(
    column: $table.usuarioId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dosis => $composableBuilder(
    column: $table.dosis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaInicio => $composableBuilder(
    column: $table.fechaInicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaFin => $composableBuilder(
    column: $table.fechaFin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get via => $composableBuilder(
    column: $table.via,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presentacion => $composableBuilder(
    column: $table.presentacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dosisCantidad => $composableBuilder(
    column: $table.dosisCantidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dosisUnidad => $composableBuilder(
    column: $table.dosisUnidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get indicacion => $composableBuilder(
    column: $table.indicacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profesionalNombre => $composableBuilder(
    column: $table.profesionalNombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profesionalEspecialidad => $composableBuilder(
    column: $table.profesionalEspecialidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordatorioHoras => $composableBuilder(
    column: $table.recordatorioHoras,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TratamientosTableOrderingComposer
    extends Composer<_$BaseLocal, $TratamientosTable> {
  $$TratamientosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usuarioId => $composableBuilder(
    column: $table.usuarioId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dosis => $composableBuilder(
    column: $table.dosis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaInicio => $composableBuilder(
    column: $table.fechaInicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaFin => $composableBuilder(
    column: $table.fechaFin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get via => $composableBuilder(
    column: $table.via,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presentacion => $composableBuilder(
    column: $table.presentacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dosisCantidad => $composableBuilder(
    column: $table.dosisCantidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dosisUnidad => $composableBuilder(
    column: $table.dosisUnidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get indicacion => $composableBuilder(
    column: $table.indicacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profesionalNombre => $composableBuilder(
    column: $table.profesionalNombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profesionalEspecialidad => $composableBuilder(
    column: $table.profesionalEspecialidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordatorioHoras => $composableBuilder(
    column: $table.recordatorioHoras,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TratamientosTableAnnotationComposer
    extends Composer<_$BaseLocal, $TratamientosTable> {
  $$TratamientosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get usuarioId =>
      $composableBuilder(column: $table.usuarioId, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get dosis =>
      $composableBuilder(column: $table.dosis, builder: (column) => column);

  GeneratedColumn<String> get frecuencia => $composableBuilder(
    column: $table.frecuencia,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaInicio => $composableBuilder(
    column: $table.fechaInicio,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaFin =>
      $composableBuilder(column: $table.fechaFin, builder: (column) => column);

  GeneratedColumn<String> get via =>
      $composableBuilder(column: $table.via, builder: (column) => column);

  GeneratedColumn<String> get presentacion => $composableBuilder(
    column: $table.presentacion,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dosisCantidad => $composableBuilder(
    column: $table.dosisCantidad,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dosisUnidad => $composableBuilder(
    column: $table.dosisUnidad,
    builder: (column) => column,
  );

  GeneratedColumn<String> get indicacion => $composableBuilder(
    column: $table.indicacion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get profesionalNombre => $composableBuilder(
    column: $table.profesionalNombre,
    builder: (column) => column,
  );

  GeneratedColumn<String> get profesionalEspecialidad => $composableBuilder(
    column: $table.profesionalEspecialidad,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<bool> get pendiente =>
      $composableBuilder(column: $table.pendiente, builder: (column) => column);

  GeneratedColumn<String> get recordatorioHoras => $composableBuilder(
    column: $table.recordatorioHoras,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);
}

class $$TratamientosTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $TratamientosTable,
          FilaTratamiento,
          $$TratamientosTableFilterComposer,
          $$TratamientosTableOrderingComposer,
          $$TratamientosTableAnnotationComposer,
          $$TratamientosTableCreateCompanionBuilder,
          $$TratamientosTableUpdateCompanionBuilder,
          (
            FilaTratamiento,
            BaseReferences<_$BaseLocal, $TratamientosTable, FilaTratamiento>,
          ),
          FilaTratamiento,
          PrefetchHooks Function()
        > {
  $$TratamientosTableTableManager(_$BaseLocal db, $TratamientosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TratamientosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TratamientosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TratamientosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> usuarioId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> dosis = const Value.absent(),
                Value<String> frecuencia = const Value.absent(),
                Value<DateTime> fechaInicio = const Value.absent(),
                Value<DateTime?> fechaFin = const Value.absent(),
                Value<String?> via = const Value.absent(),
                Value<String?> presentacion = const Value.absent(),
                Value<double?> dosisCantidad = const Value.absent(),
                Value<String?> dosisUnidad = const Value.absent(),
                Value<String?> indicacion = const Value.absent(),
                Value<String?> profesionalNombre = const Value.absent(),
                Value<String?> profesionalEspecialidad = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<String?> recordatorioHoras = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TratamientosCompanion(
                id: id,
                usuarioId: usuarioId,
                nombre: nombre,
                dosis: dosis,
                frecuencia: frecuencia,
                fechaInicio: fechaInicio,
                fechaFin: fechaFin,
                via: via,
                presentacion: presentacion,
                dosisCantidad: dosisCantidad,
                dosisUnidad: dosisUnidad,
                indicacion: indicacion,
                profesionalNombre: profesionalNombre,
                profesionalEspecialidad: profesionalEspecialidad,
                activo: activo,
                pendiente: pendiente,
                recordatorioHoras: recordatorioHoras,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String usuarioId,
                required String nombre,
                required String dosis,
                required String frecuencia,
                required DateTime fechaInicio,
                Value<DateTime?> fechaFin = const Value.absent(),
                Value<String?> via = const Value.absent(),
                Value<String?> presentacion = const Value.absent(),
                Value<double?> dosisCantidad = const Value.absent(),
                Value<String?> dosisUnidad = const Value.absent(),
                Value<String?> indicacion = const Value.absent(),
                Value<String?> profesionalNombre = const Value.absent(),
                Value<String?> profesionalEspecialidad = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<String?> recordatorioHoras = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TratamientosCompanion.insert(
                id: id,
                usuarioId: usuarioId,
                nombre: nombre,
                dosis: dosis,
                frecuencia: frecuencia,
                fechaInicio: fechaInicio,
                fechaFin: fechaFin,
                via: via,
                presentacion: presentacion,
                dosisCantidad: dosisCantidad,
                dosisUnidad: dosisUnidad,
                indicacion: indicacion,
                profesionalNombre: profesionalNombre,
                profesionalEspecialidad: profesionalEspecialidad,
                activo: activo,
                pendiente: pendiente,
                recordatorioHoras: recordatorioHoras,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TratamientosTable, FilaTratamiento>(table),
                  BaseReferences<
                    _$BaseLocal,
                    $TratamientosTable,
                    FilaTratamiento
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TratamientosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $TratamientosTable,
      FilaTratamiento,
      $$TratamientosTableFilterComposer,
      $$TratamientosTableOrderingComposer,
      $$TratamientosTableAnnotationComposer,
      $$TratamientosTableCreateCompanionBuilder,
      $$TratamientosTableUpdateCompanionBuilder,
      (
        FilaTratamiento,
        BaseReferences<_$BaseLocal, $TratamientosTable, FilaTratamiento>,
      ),
      FilaTratamiento,
      PrefetchHooks Function()
    >;
typedef $$CambiosTableCreateCompanionBuilder = CambiosCompanion Function({
  required String id,
  required String usuarioId,
  required DateTime fecha,
  Value<String> descripcion,
  Value<bool> activo,
  Value<bool> pendiente,
  Value<DateTime> creadoEn,
  Value<int> rowid,
});
typedef $$CambiosTableUpdateCompanionBuilder = CambiosCompanion Function({
  Value<String> id,
  Value<String> usuarioId,
  Value<DateTime> fecha,
  Value<String> descripcion,
  Value<bool> activo,
  Value<bool> pendiente,
  Value<DateTime> creadoEn,
  Value<int> rowid,
});

final class $$CambiosTableReferences
    extends BaseReferences<_$BaseLocal, $CambiosTable, FilaCambio> {
  $$CambiosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AdjuntosTable, List<FilaAdjunto>>
  _adjuntosRefsTable(_$BaseLocal db) => MultiTypedResultKey.fromTable(
    db.adjuntos,
    aliasName: 'cambios__id__adjuntos__cambio_id',
  );

  $$AdjuntosTableProcessedTableManager get adjuntosRefs {
    final manager = $$AdjuntosTableTableManager(
      $_db,
      $_db.adjuntos,
    ).filter((f) => f.cambioId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_adjuntosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CambiosTableFilterComposer
    extends Composer<_$BaseLocal, $CambiosTable> {
  $$CambiosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usuarioId => $composableBuilder(
    column: $table.usuarioId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> adjuntosRefs(
    Expression<bool> Function($$AdjuntosTableFilterComposer f) f,
  ) {
    final $$AdjuntosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.adjuntos,
      getReferencedColumn: (t) => t.cambioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdjuntosTableFilterComposer(
            $db: $db,
            $table: $db.adjuntos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CambiosTableOrderingComposer
    extends Composer<_$BaseLocal, $CambiosTable> {
  $$CambiosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usuarioId => $composableBuilder(
    column: $table.usuarioId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendiente => $composableBuilder(
    column: $table.pendiente,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CambiosTableAnnotationComposer
    extends Composer<_$BaseLocal, $CambiosTable> {
  $$CambiosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get usuarioId =>
      $composableBuilder(column: $table.usuarioId, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<bool> get pendiente =>
      $composableBuilder(column: $table.pendiente, builder: (column) => column);

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  Expression<T> adjuntosRefs<T extends Object>(
    Expression<T> Function($$AdjuntosTableAnnotationComposer a) f,
  ) {
    final $$AdjuntosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.adjuntos,
      getReferencedColumn: (t) => t.cambioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AdjuntosTableAnnotationComposer(
            $db: $db,
            $table: $db.adjuntos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CambiosTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $CambiosTable,
          FilaCambio,
          $$CambiosTableFilterComposer,
          $$CambiosTableOrderingComposer,
          $$CambiosTableAnnotationComposer,
          $$CambiosTableCreateCompanionBuilder,
          $$CambiosTableUpdateCompanionBuilder,
          (FilaCambio, $$CambiosTableReferences),
          FilaCambio,
          PrefetchHooks Function({bool adjuntosRefs})
        > {
  $$CambiosTableTableManager(_$BaseLocal db, $CambiosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CambiosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CambiosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CambiosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> usuarioId = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String> descripcion = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CambiosCompanion(
                id: id,
                usuarioId: usuarioId,
                fecha: fecha,
                descripcion: descripcion,
                activo: activo,
                pendiente: pendiente,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String usuarioId,
                required DateTime fecha,
                Value<String> descripcion = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<bool> pendiente = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CambiosCompanion.insert(
                id: id,
                usuarioId: usuarioId,
                fecha: fecha,
                descripcion: descripcion,
                activo: activo,
                pendiente: pendiente,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CambiosTable, FilaCambio>(table),
                  $$CambiosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({adjuntosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (adjuntosRefs) db.adjuntos],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (adjuntosRefs)
                    await $_getPrefetchedData<
                      FilaCambio,
                      $CambiosTable,
                      FilaAdjunto
                    >(
                      currentTable: table,
                      referencedTable: $$CambiosTableReferences
                          ._adjuntosRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CambiosTableReferences(db, table, p0).adjuntosRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.cambioId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CambiosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $CambiosTable,
      FilaCambio,
      $$CambiosTableFilterComposer,
      $$CambiosTableOrderingComposer,
      $$CambiosTableAnnotationComposer,
      $$CambiosTableCreateCompanionBuilder,
      $$CambiosTableUpdateCompanionBuilder,
      (FilaCambio, $$CambiosTableReferences),
      FilaCambio,
      PrefetchHooks Function({bool adjuntosRefs})
    >;
typedef $$AdjuntosTableCreateCompanionBuilder = AdjuntosCompanion Function({
  required String id,
  required String cambioId,
  required String tipo,
  Value<String> nombre,
  required Uint8List contenido,
  Value<DateTime> creadoEn,
  Value<int> rowid,
});
typedef $$AdjuntosTableUpdateCompanionBuilder = AdjuntosCompanion Function({
  Value<String> id,
  Value<String> cambioId,
  Value<String> tipo,
  Value<String> nombre,
  Value<Uint8List> contenido,
  Value<DateTime> creadoEn,
  Value<int> rowid,
});

final class $$AdjuntosTableReferences
    extends BaseReferences<_$BaseLocal, $AdjuntosTable, FilaAdjunto> {
  $$AdjuntosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CambiosTable _cambioIdTable(_$BaseLocal db) =>
      db.cambios.createAlias('adjuntos__cambio_id__cambios__id');

  $$CambiosTableProcessedTableManager get cambioId {
    final $_column = $_itemColumn<String>('cambio_id')!;

    final manager = $$CambiosTableTableManager(
      $_db,
      $_db.cambios,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cambioIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AdjuntosTableFilterComposer
    extends Composer<_$BaseLocal, $AdjuntosTable> {
  $$AdjuntosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get contenido => $composableBuilder(
    column: $table.contenido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  $$CambiosTableFilterComposer get cambioId {
    final $$CambiosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cambioId,
      referencedTable: $db.cambios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CambiosTableFilterComposer(
            $db: $db,
            $table: $db.cambios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdjuntosTableOrderingComposer
    extends Composer<_$BaseLocal, $AdjuntosTable> {
  $$AdjuntosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get contenido => $composableBuilder(
    column: $table.contenido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  $$CambiosTableOrderingComposer get cambioId {
    final $$CambiosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cambioId,
      referencedTable: $db.cambios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CambiosTableOrderingComposer(
            $db: $db,
            $table: $db.cambios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdjuntosTableAnnotationComposer
    extends Composer<_$BaseLocal, $AdjuntosTable> {
  $$AdjuntosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<Uint8List> get contenido =>
      $composableBuilder(column: $table.contenido, builder: (column) => column);

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  $$CambiosTableAnnotationComposer get cambioId {
    final $$CambiosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cambioId,
      referencedTable: $db.cambios,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CambiosTableAnnotationComposer(
            $db: $db,
            $table: $db.cambios,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AdjuntosTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $AdjuntosTable,
          FilaAdjunto,
          $$AdjuntosTableFilterComposer,
          $$AdjuntosTableOrderingComposer,
          $$AdjuntosTableAnnotationComposer,
          $$AdjuntosTableCreateCompanionBuilder,
          $$AdjuntosTableUpdateCompanionBuilder,
          (FilaAdjunto, $$AdjuntosTableReferences),
          FilaAdjunto,
          PrefetchHooks Function({bool cambioId})
        > {
  $$AdjuntosTableTableManager(_$BaseLocal db, $AdjuntosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdjuntosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdjuntosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdjuntosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cambioId = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<Uint8List> contenido = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdjuntosCompanion(
                id: id,
                cambioId: cambioId,
                tipo: tipo,
                nombre: nombre,
                contenido: contenido,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cambioId,
                required String tipo,
                Value<String> nombre = const Value.absent(),
                required Uint8List contenido,
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdjuntosCompanion.insert(
                id: id,
                cambioId: cambioId,
                tipo: tipo,
                nombre: nombre,
                contenido: contenido,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AdjuntosTable, FilaAdjunto>(table),
                  $$AdjuntosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cambioId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cambioId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.cambioId,
                        referencedTable: $$AdjuntosTableReferences
                            ._cambioIdTable(db),
                        referencedColumn: $$AdjuntosTableReferences
                            ._cambioIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AdjuntosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $AdjuntosTable,
      FilaAdjunto,
      $$AdjuntosTableFilterComposer,
      $$AdjuntosTableOrderingComposer,
      $$AdjuntosTableAnnotationComposer,
      $$AdjuntosTableCreateCompanionBuilder,
      $$AdjuntosTableUpdateCompanionBuilder,
      (FilaAdjunto, $$AdjuntosTableReferences),
      FilaAdjunto,
      PrefetchHooks Function({bool cambioId})
    >;
typedef $$AjustesTableCreateCompanionBuilder = AjustesCompanion Function({
  required String clave,
  required String valor,
  Value<int> rowid,
});
typedef $$AjustesTableUpdateCompanionBuilder = AjustesCompanion Function({
  Value<String> clave,
  Value<String> valor,
  Value<int> rowid,
});

class $$AjustesTableFilterComposer
    extends Composer<_$BaseLocal, $AjustesTable> {
  $$AjustesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AjustesTableOrderingComposer
    extends Composer<_$BaseLocal, $AjustesTable> {
  $$AjustesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AjustesTableAnnotationComposer
    extends Composer<_$BaseLocal, $AjustesTable> {
  $$AjustesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clave =>
      $composableBuilder(column: $table.clave, builder: (column) => column);

  GeneratedColumn<String> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);
}

class $$AjustesTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $AjustesTable,
          FilaAjuste,
          $$AjustesTableFilterComposer,
          $$AjustesTableOrderingComposer,
          $$AjustesTableAnnotationComposer,
          $$AjustesTableCreateCompanionBuilder,
          $$AjustesTableUpdateCompanionBuilder,
          (FilaAjuste, BaseReferences<_$BaseLocal, $AjustesTable, FilaAjuste>),
          FilaAjuste,
          PrefetchHooks Function()
        > {
  $$AjustesTableTableManager(_$BaseLocal db, $AjustesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AjustesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AjustesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AjustesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> clave = const Value.absent(),
            Value<String> valor = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AjustesCompanion(clave: clave, valor: valor, rowid: rowid),
          createCompanionCallback:
              ({
                required String clave,
                required String valor,
                Value<int> rowid = const Value.absent(),
              }) => AjustesCompanion.insert(
                clave: clave,
                valor: valor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AjustesTable, FilaAjuste>(table),
                  BaseReferences<_$BaseLocal, $AjustesTable, FilaAjuste>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AjustesTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $AjustesTable,
      FilaAjuste,
      $$AjustesTableFilterComposer,
      $$AjustesTableOrderingComposer,
      $$AjustesTableAnnotationComposer,
      $$AjustesTableCreateCompanionBuilder,
      $$AjustesTableUpdateCompanionBuilder,
      (FilaAjuste, BaseReferences<_$BaseLocal, $AjustesTable, FilaAjuste>),
      FilaAjuste,
      PrefetchHooks Function()
    >;

class $BaseLocalManager {
  final _$BaseLocal _db;
  $BaseLocalManager(this._db);
  $$TratamientosTableTableManager get tratamientos =>
      $$TratamientosTableTableManager(_db, _db.tratamientos);
  $$CambiosTableTableManager get cambios =>
      $$CambiosTableTableManager(_db, _db.cambios);
  $$AdjuntosTableTableManager get adjuntos =>
      $$AdjuntosTableTableManager(_db, _db.adjuntos);
  $$AjustesTableTableManager get ajustes =>
      $$AjustesTableTableManager(_db, _db.ajustes);
}
