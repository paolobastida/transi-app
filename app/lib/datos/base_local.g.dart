// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_local.dart';

// ignore_for_file: type=lint
class $ProfesionalesTable extends Profesionales
    with TableInfo<$ProfesionalesTable, FilaProfesional> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfesionalesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _especialidadMeta = const VerificationMeta(
    'especialidad',
  );
  @override
  late final GeneratedColumn<String> especialidad = GeneratedColumn<String>(
    'especialidad',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    especialidad,
    activo,
    creadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profesionales';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaProfesional> instance, {
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
    if (data.containsKey('especialidad')) {
      context.handle(
        _especialidadMeta,
        especialidad.isAcceptableOrUnknown(
          data['especialidad']!,
          _especialidadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_especialidadMeta);
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
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
  FilaProfesional map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaProfesional(
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
      especialidad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}especialidad'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
    );
  }

  @override
  $ProfesionalesTable createAlias(String alias) {
    return $ProfesionalesTable(attachedDatabase, alias);
  }
}

class FilaProfesional extends DataClass implements Insertable<FilaProfesional> {
  final String id;
  final String usuarioId;
  final String nombre;
  final String especialidad;
  final bool activo;
  final DateTime creadoEn;
  const FilaProfesional({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.especialidad,
    required this.activo,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['usuario_id'] = Variable<String>(usuarioId);
    map['nombre'] = Variable<String>(nombre);
    map['especialidad'] = Variable<String>(especialidad);
    map['activo'] = Variable<bool>(activo);
    map['creado_en'] = Variable<DateTime>(creadoEn);
    return map;
  }

  ProfesionalesCompanion toCompanion(bool nullToAbsent) {
    return ProfesionalesCompanion(
      id: Value(id),
      usuarioId: Value(usuarioId),
      nombre: Value(nombre),
      especialidad: Value(especialidad),
      activo: Value(activo),
      creadoEn: Value(creadoEn),
    );
  }

  factory FilaProfesional.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaProfesional(
      id: serializer.fromJson<String>(json['id']),
      usuarioId: serializer.fromJson<String>(json['usuarioId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      especialidad: serializer.fromJson<String>(json['especialidad']),
      activo: serializer.fromJson<bool>(json['activo']),
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
      'especialidad': serializer.toJson<String>(especialidad),
      'activo': serializer.toJson<bool>(activo),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  FilaProfesional copyWith({
    String? id,
    String? usuarioId,
    String? nombre,
    String? especialidad,
    bool? activo,
    DateTime? creadoEn,
  }) => FilaProfesional(
    id: id ?? this.id,
    usuarioId: usuarioId ?? this.usuarioId,
    nombre: nombre ?? this.nombre,
    especialidad: especialidad ?? this.especialidad,
    activo: activo ?? this.activo,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  FilaProfesional copyWithCompanion(ProfesionalesCompanion data) {
    return FilaProfesional(
      id: data.id.present ? data.id.value : this.id,
      usuarioId: data.usuarioId.present ? data.usuarioId.value : this.usuarioId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      especialidad: data.especialidad.present
          ? data.especialidad.value
          : this.especialidad,
      activo: data.activo.present ? data.activo.value : this.activo,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaProfesional(')
          ..write('id: $id, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('nombre: $nombre, ')
          ..write('especialidad: $especialidad, ')
          ..write('activo: $activo, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, usuarioId, nombre, especialidad, activo, creadoEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaProfesional &&
          other.id == this.id &&
          other.usuarioId == this.usuarioId &&
          other.nombre == this.nombre &&
          other.especialidad == this.especialidad &&
          other.activo == this.activo &&
          other.creadoEn == this.creadoEn);
}

class ProfesionalesCompanion extends UpdateCompanion<FilaProfesional> {
  final Value<String> id;
  final Value<String> usuarioId;
  final Value<String> nombre;
  final Value<String> especialidad;
  final Value<bool> activo;
  final Value<DateTime> creadoEn;
  final Value<int> rowid;
  const ProfesionalesCompanion({
    this.id = const Value.absent(),
    this.usuarioId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.especialidad = const Value.absent(),
    this.activo = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfesionalesCompanion.insert({
    required String id,
    required String usuarioId,
    required String nombre,
    required String especialidad,
    this.activo = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       usuarioId = Value(usuarioId),
       nombre = Value(nombre),
       especialidad = Value(especialidad);
  static Insertable<FilaProfesional> custom({
    Expression<String>? id,
    Expression<String>? usuarioId,
    Expression<String>? nombre,
    Expression<String>? especialidad,
    Expression<bool>? activo,
    Expression<DateTime>? creadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (usuarioId != null) 'usuario_id': usuarioId,
      if (nombre != null) 'nombre': nombre,
      if (especialidad != null) 'especialidad': especialidad,
      if (activo != null) 'activo': activo,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfesionalesCompanion copyWith({
    Value<String>? id,
    Value<String>? usuarioId,
    Value<String>? nombre,
    Value<String>? especialidad,
    Value<bool>? activo,
    Value<DateTime>? creadoEn,
    Value<int>? rowid,
  }) {
    return ProfesionalesCompanion(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      nombre: nombre ?? this.nombre,
      especialidad: especialidad ?? this.especialidad,
      activo: activo ?? this.activo,
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
    if (especialidad.present) {
      map['especialidad'] = Variable<String>(especialidad.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
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
    return (StringBuffer('ProfesionalesCompanion(')
          ..write('id: $id, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('nombre: $nombre, ')
          ..write('especialidad: $especialidad, ')
          ..write('activo: $activo, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

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
  static const VerificationMeta _profesionalIdMeta = const VerificationMeta(
    'profesionalId',
  );
  @override
  late final GeneratedColumn<String> profesionalId = GeneratedColumn<String>(
    'profesional_id',
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
    profesionalId,
    activo,
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
    if (data.containsKey('profesional_id')) {
      context.handle(
        _profesionalIdMeta,
        profesionalId.isAcceptableOrUnknown(
          data['profesional_id']!,
          _profesionalIdMeta,
        ),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
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
      profesionalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profesional_id'],
      ),
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
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
  final String? profesionalId;
  final bool activo;
  final DateTime creadoEn;
  const FilaTratamiento({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.dosis,
    required this.frecuencia,
    required this.fechaInicio,
    this.fechaFin,
    this.profesionalId,
    required this.activo,
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
    if (!nullToAbsent || profesionalId != null) {
      map['profesional_id'] = Variable<String>(profesionalId);
    }
    map['activo'] = Variable<bool>(activo);
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
      profesionalId: profesionalId == null && nullToAbsent
          ? const Value.absent()
          : Value(profesionalId),
      activo: Value(activo),
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
      profesionalId: serializer.fromJson<String?>(json['profesionalId']),
      activo: serializer.fromJson<bool>(json['activo']),
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
      'profesionalId': serializer.toJson<String?>(profesionalId),
      'activo': serializer.toJson<bool>(activo),
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
    Value<String?> profesionalId = const Value.absent(),
    bool? activo,
    DateTime? creadoEn,
  }) => FilaTratamiento(
    id: id ?? this.id,
    usuarioId: usuarioId ?? this.usuarioId,
    nombre: nombre ?? this.nombre,
    dosis: dosis ?? this.dosis,
    frecuencia: frecuencia ?? this.frecuencia,
    fechaInicio: fechaInicio ?? this.fechaInicio,
    fechaFin: fechaFin.present ? fechaFin.value : this.fechaFin,
    profesionalId: profesionalId.present
        ? profesionalId.value
        : this.profesionalId,
    activo: activo ?? this.activo,
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
      profesionalId: data.profesionalId.present
          ? data.profesionalId.value
          : this.profesionalId,
      activo: data.activo.present ? data.activo.value : this.activo,
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
          ..write('profesionalId: $profesionalId, ')
          ..write('activo: $activo, ')
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
    profesionalId,
    activo,
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
          other.profesionalId == this.profesionalId &&
          other.activo == this.activo &&
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
  final Value<String?> profesionalId;
  final Value<bool> activo;
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
    this.profesionalId = const Value.absent(),
    this.activo = const Value.absent(),
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
    this.profesionalId = const Value.absent(),
    this.activo = const Value.absent(),
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
    Expression<String>? profesionalId,
    Expression<bool>? activo,
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
      if (profesionalId != null) 'profesional_id': profesionalId,
      if (activo != null) 'activo': activo,
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
    Value<String?>? profesionalId,
    Value<bool>? activo,
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
      profesionalId: profesionalId ?? this.profesionalId,
      activo: activo ?? this.activo,
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
    if (profesionalId.present) {
      map['profesional_id'] = Variable<String>(profesionalId.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
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
          ..write('profesionalId: $profesionalId, ')
          ..write('activo: $activo, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$BaseLocal extends GeneratedDatabase {
  _$BaseLocal(QueryExecutor e) : super(e);
  $BaseLocalManager get managers => $BaseLocalManager(this);
  late final $ProfesionalesTable profesionales = $ProfesionalesTable(this);
  late final $TratamientosTable tratamientos = $TratamientosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profesionales,
    tratamientos,
  ];
}

typedef $$ProfesionalesTableCreateCompanionBuilder =
    ProfesionalesCompanion Function({
      required String id,
      required String usuarioId,
      required String nombre,
      required String especialidad,
      Value<bool> activo,
      Value<DateTime> creadoEn,
      Value<int> rowid,
    });
typedef $$ProfesionalesTableUpdateCompanionBuilder =
    ProfesionalesCompanion Function({
      Value<String> id,
      Value<String> usuarioId,
      Value<String> nombre,
      Value<String> especialidad,
      Value<bool> activo,
      Value<DateTime> creadoEn,
      Value<int> rowid,
    });

class $$ProfesionalesTableFilterComposer
    extends Composer<_$BaseLocal, $ProfesionalesTable> {
  $$ProfesionalesTableFilterComposer({
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

  ColumnFilters<String> get especialidad => $composableBuilder(
    column: $table.especialidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfesionalesTableOrderingComposer
    extends Composer<_$BaseLocal, $ProfesionalesTable> {
  $$ProfesionalesTableOrderingComposer({
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

  ColumnOrderings<String> get especialidad => $composableBuilder(
    column: $table.especialidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfesionalesTableAnnotationComposer
    extends Composer<_$BaseLocal, $ProfesionalesTable> {
  $$ProfesionalesTableAnnotationComposer({
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

  GeneratedColumn<String> get especialidad => $composableBuilder(
    column: $table.especialidad,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);
}

class $$ProfesionalesTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $ProfesionalesTable,
          FilaProfesional,
          $$ProfesionalesTableFilterComposer,
          $$ProfesionalesTableOrderingComposer,
          $$ProfesionalesTableAnnotationComposer,
          $$ProfesionalesTableCreateCompanionBuilder,
          $$ProfesionalesTableUpdateCompanionBuilder,
          (
            FilaProfesional,
            BaseReferences<_$BaseLocal, $ProfesionalesTable, FilaProfesional>,
          ),
          FilaProfesional,
          PrefetchHooks Function()
        > {
  $$ProfesionalesTableTableManager(_$BaseLocal db, $ProfesionalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfesionalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfesionalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfesionalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> usuarioId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> especialidad = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfesionalesCompanion(
                id: id,
                usuarioId: usuarioId,
                nombre: nombre,
                especialidad: especialidad,
                activo: activo,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String usuarioId,
                required String nombre,
                required String especialidad,
                Value<bool> activo = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfesionalesCompanion.insert(
                id: id,
                usuarioId: usuarioId,
                nombre: nombre,
                especialidad: especialidad,
                activo: activo,
                creadoEn: creadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfesionalesTable, FilaProfesional>(table),
                  BaseReferences<
                    _$BaseLocal,
                    $ProfesionalesTable,
                    FilaProfesional
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfesionalesTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $ProfesionalesTable,
      FilaProfesional,
      $$ProfesionalesTableFilterComposer,
      $$ProfesionalesTableOrderingComposer,
      $$ProfesionalesTableAnnotationComposer,
      $$ProfesionalesTableCreateCompanionBuilder,
      $$ProfesionalesTableUpdateCompanionBuilder,
      (
        FilaProfesional,
        BaseReferences<_$BaseLocal, $ProfesionalesTable, FilaProfesional>,
      ),
      FilaProfesional,
      PrefetchHooks Function()
    >;
typedef $$TratamientosTableCreateCompanionBuilder =
    TratamientosCompanion Function({
      required String id,
      required String usuarioId,
      required String nombre,
      required String dosis,
      required String frecuencia,
      required DateTime fechaInicio,
      Value<DateTime?> fechaFin,
      Value<String?> profesionalId,
      Value<bool> activo,
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
      Value<String?> profesionalId,
      Value<bool> activo,
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

  ColumnFilters<String> get profesionalId => $composableBuilder(
    column: $table.profesionalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
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

  ColumnOrderings<String> get profesionalId => $composableBuilder(
    column: $table.profesionalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
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

  GeneratedColumn<String> get profesionalId => $composableBuilder(
    column: $table.profesionalId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

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
                Value<String?> profesionalId = const Value.absent(),
                Value<bool> activo = const Value.absent(),
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
                profesionalId: profesionalId,
                activo: activo,
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
                Value<String?> profesionalId = const Value.absent(),
                Value<bool> activo = const Value.absent(),
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
                profesionalId: profesionalId,
                activo: activo,
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

class $BaseLocalManager {
  final _$BaseLocal _db;
  $BaseLocalManager(this._db);
  $$ProfesionalesTableTableManager get profesionales =>
      $$ProfesionalesTableTableManager(_db, _db.profesionales);
  $$TratamientosTableTableManager get tratamientos =>
      $$TratamientosTableTableManager(_db, _db.tratamientos);
}
