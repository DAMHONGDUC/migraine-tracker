// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AttacksTable extends Attacks with TableInfo<$AttacksTable, AttackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intensityMeta = const VerificationMeta(
    'intensity',
  );
  @override
  late final GeneratedColumn<int> intensity = GeneratedColumn<int>(
    'intensity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<HeadLocation, String> location =
      GeneratedColumn<String>(
        'location',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<HeadLocation>($AttacksTable.$converterlocation);
  static const VerificationMeta _medicationNameMeta = const VerificationMeta(
    'medicationName',
  );
  @override
  late final GeneratedColumn<String> medicationName = GeneratedColumn<String>(
    'medication_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> symptoms =
      GeneratedColumn<String>(
        'symptoms',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($AttacksTable.$convertersymptoms);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> triggers =
      GeneratedColumn<String>(
        'triggers',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($AttacksTable.$convertertriggers);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    intensity,
    location,
    medicationName,
    symptoms,
    triggers,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attacks';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('intensity')) {
      context.handle(
        _intensityMeta,
        intensity.isAcceptableOrUnknown(data['intensity']!, _intensityMeta),
      );
    } else if (isInserting) {
      context.missing(_intensityMeta);
    }
    if (data.containsKey('medication_name')) {
      context.handle(
        _medicationNameMeta,
        medicationName.isAcceptableOrUnknown(
          data['medication_name']!,
          _medicationNameMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttackRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      intensity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intensity'],
      )!,
      location: $AttacksTable.$converterlocation.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}location'],
        )!,
      ),
      medicationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_name'],
      ),
      symptoms: $AttacksTable.$convertersymptoms.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}symptoms'],
        )!,
      ),
      triggers: $AttacksTable.$convertertriggers.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}triggers'],
        )!,
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $AttacksTable createAlias(String alias) {
    return $AttacksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<HeadLocation, String, String> $converterlocation =
      const EnumNameConverter<HeadLocation>(HeadLocation.values);
  static TypeConverter<List<String>, String> $convertersymptoms =
      const StringListConverter();
  static TypeConverter<List<String>, String> $convertertriggers =
      const StringListConverter();
}

class AttackRow extends DataClass implements Insertable<AttackRow> {
  final String id;

  /// Stored as UTC unix timestamp.
  final DateTime startedAt;
  final int intensity;
  final HeadLocation location;
  final String? medicationName;
  final List<String> symptoms;
  final List<String> triggers;
  final String? notes;
  const AttackRow({
    required this.id,
    required this.startedAt,
    required this.intensity,
    required this.location,
    this.medicationName,
    required this.symptoms,
    required this.triggers,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['intensity'] = Variable<int>(intensity);
    {
      map['location'] = Variable<String>(
        $AttacksTable.$converterlocation.toSql(location),
      );
    }
    if (!nullToAbsent || medicationName != null) {
      map['medication_name'] = Variable<String>(medicationName);
    }
    {
      map['symptoms'] = Variable<String>(
        $AttacksTable.$convertersymptoms.toSql(symptoms),
      );
    }
    {
      map['triggers'] = Variable<String>(
        $AttacksTable.$convertertriggers.toSql(triggers),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  AttacksCompanion toCompanion(bool nullToAbsent) {
    return AttacksCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      intensity: Value(intensity),
      location: Value(location),
      medicationName: medicationName == null && nullToAbsent
          ? const Value.absent()
          : Value(medicationName),
      symptoms: Value(symptoms),
      triggers: Value(triggers),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory AttackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttackRow(
      id: serializer.fromJson<String>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      intensity: serializer.fromJson<int>(json['intensity']),
      location: $AttacksTable.$converterlocation.fromJson(
        serializer.fromJson<String>(json['location']),
      ),
      medicationName: serializer.fromJson<String?>(json['medicationName']),
      symptoms: serializer.fromJson<List<String>>(json['symptoms']),
      triggers: serializer.fromJson<List<String>>(json['triggers']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'intensity': serializer.toJson<int>(intensity),
      'location': serializer.toJson<String>(
        $AttacksTable.$converterlocation.toJson(location),
      ),
      'medicationName': serializer.toJson<String?>(medicationName),
      'symptoms': serializer.toJson<List<String>>(symptoms),
      'triggers': serializer.toJson<List<String>>(triggers),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  AttackRow copyWith({
    String? id,
    DateTime? startedAt,
    int? intensity,
    HeadLocation? location,
    Value<String?> medicationName = const Value.absent(),
    List<String>? symptoms,
    List<String>? triggers,
    Value<String?> notes = const Value.absent(),
  }) => AttackRow(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    intensity: intensity ?? this.intensity,
    location: location ?? this.location,
    medicationName: medicationName.present
        ? medicationName.value
        : this.medicationName,
    symptoms: symptoms ?? this.symptoms,
    triggers: triggers ?? this.triggers,
    notes: notes.present ? notes.value : this.notes,
  );
  AttackRow copyWithCompanion(AttacksCompanion data) {
    return AttackRow(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      intensity: data.intensity.present ? data.intensity.value : this.intensity,
      location: data.location.present ? data.location.value : this.location,
      medicationName: data.medicationName.present
          ? data.medicationName.value
          : this.medicationName,
      symptoms: data.symptoms.present ? data.symptoms.value : this.symptoms,
      triggers: data.triggers.present ? data.triggers.value : this.triggers,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttackRow(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('intensity: $intensity, ')
          ..write('location: $location, ')
          ..write('medicationName: $medicationName, ')
          ..write('symptoms: $symptoms, ')
          ..write('triggers: $triggers, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    intensity,
    location,
    medicationName,
    symptoms,
    triggers,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttackRow &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.intensity == this.intensity &&
          other.location == this.location &&
          other.medicationName == this.medicationName &&
          other.symptoms == this.symptoms &&
          other.triggers == this.triggers &&
          other.notes == this.notes);
}

class AttacksCompanion extends UpdateCompanion<AttackRow> {
  final Value<String> id;
  final Value<DateTime> startedAt;
  final Value<int> intensity;
  final Value<HeadLocation> location;
  final Value<String?> medicationName;
  final Value<List<String>> symptoms;
  final Value<List<String>> triggers;
  final Value<String?> notes;
  final Value<int> rowid;
  const AttacksCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.intensity = const Value.absent(),
    this.location = const Value.absent(),
    this.medicationName = const Value.absent(),
    this.symptoms = const Value.absent(),
    this.triggers = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttacksCompanion.insert({
    required String id,
    required DateTime startedAt,
    required int intensity,
    required HeadLocation location,
    this.medicationName = const Value.absent(),
    this.symptoms = const Value.absent(),
    this.triggers = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt),
       intensity = Value(intensity),
       location = Value(location);
  static Insertable<AttackRow> custom({
    Expression<String>? id,
    Expression<DateTime>? startedAt,
    Expression<int>? intensity,
    Expression<String>? location,
    Expression<String>? medicationName,
    Expression<String>? symptoms,
    Expression<String>? triggers,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (intensity != null) 'intensity': intensity,
      if (location != null) 'location': location,
      if (medicationName != null) 'medication_name': medicationName,
      if (symptoms != null) 'symptoms': symptoms,
      if (triggers != null) 'triggers': triggers,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttacksCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? startedAt,
    Value<int>? intensity,
    Value<HeadLocation>? location,
    Value<String?>? medicationName,
    Value<List<String>>? symptoms,
    Value<List<String>>? triggers,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return AttacksCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      intensity: intensity ?? this.intensity,
      location: location ?? this.location,
      medicationName: medicationName ?? this.medicationName,
      symptoms: symptoms ?? this.symptoms,
      triggers: triggers ?? this.triggers,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (intensity.present) {
      map['intensity'] = Variable<int>(intensity.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(
        $AttacksTable.$converterlocation.toSql(location.value),
      );
    }
    if (medicationName.present) {
      map['medication_name'] = Variable<String>(medicationName.value);
    }
    if (symptoms.present) {
      map['symptoms'] = Variable<String>(
        $AttacksTable.$convertersymptoms.toSql(symptoms.value),
      );
    }
    if (triggers.present) {
      map['triggers'] = Variable<String>(
        $AttacksTable.$convertertriggers.toSql(triggers.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttacksCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('intensity: $intensity, ')
          ..write('location: $location, ')
          ..write('medicationName: $medicationName, ')
          ..write('symptoms: $symptoms, ')
          ..write('triggers: $triggers, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeatherSnapshotsTable extends WeatherSnapshots
    with TableInfo<$WeatherSnapshotsTable, WeatherSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeatherSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attackIdMeta = const VerificationMeta(
    'attackId',
  );
  @override
  late final GeneratedColumn<String> attackId = GeneratedColumn<String>(
    'attack_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES attacks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pressureHpaMeta = const VerificationMeta(
    'pressureHpa',
  );
  @override
  late final GeneratedColumn<double> pressureHpa = GeneratedColumn<double>(
    'pressure_hpa',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pressureDelta24hHpaMeta =
      const VerificationMeta('pressureDelta24hHpa');
  @override
  late final GeneratedColumn<double> pressureDelta24hHpa =
      GeneratedColumn<double>(
        'pressure_delta24h_hpa',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _humidityPercentMeta = const VerificationMeta(
    'humidityPercent',
  );
  @override
  late final GeneratedColumn<double> humidityPercent = GeneratedColumn<double>(
    'humidity_percent',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperatureCelsiusMeta =
      const VerificationMeta('temperatureCelsius');
  @override
  late final GeneratedColumn<double> temperatureCelsius =
      GeneratedColumn<double>(
        'temperature_celsius',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    attackId,
    capturedAt,
    pressureHpa,
    pressureDelta24hHpa,
    humidityPercent,
    temperatureCelsius,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weather_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeatherSnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attack_id')) {
      context.handle(
        _attackIdMeta,
        attackId.isAcceptableOrUnknown(data['attack_id']!, _attackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_attackIdMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('pressure_hpa')) {
      context.handle(
        _pressureHpaMeta,
        pressureHpa.isAcceptableOrUnknown(
          data['pressure_hpa']!,
          _pressureHpaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pressureHpaMeta);
    }
    if (data.containsKey('pressure_delta24h_hpa')) {
      context.handle(
        _pressureDelta24hHpaMeta,
        pressureDelta24hHpa.isAcceptableOrUnknown(
          data['pressure_delta24h_hpa']!,
          _pressureDelta24hHpaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pressureDelta24hHpaMeta);
    }
    if (data.containsKey('humidity_percent')) {
      context.handle(
        _humidityPercentMeta,
        humidityPercent.isAcceptableOrUnknown(
          data['humidity_percent']!,
          _humidityPercentMeta,
        ),
      );
    }
    if (data.containsKey('temperature_celsius')) {
      context.handle(
        _temperatureCelsiusMeta,
        temperatureCelsius.isAcceptableOrUnknown(
          data['temperature_celsius']!,
          _temperatureCelsiusMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attackId};
  @override
  WeatherSnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeatherSnapshotRow(
      attackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attack_id'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      pressureHpa: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pressure_hpa'],
      )!,
      pressureDelta24hHpa: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pressure_delta24h_hpa'],
      )!,
      humidityPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}humidity_percent'],
      ),
      temperatureCelsius: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature_celsius'],
      ),
    );
  }

  @override
  $WeatherSnapshotsTable createAlias(String alias) {
    return $WeatherSnapshotsTable(attachedDatabase, alias);
  }
}

class WeatherSnapshotRow extends DataClass
    implements Insertable<WeatherSnapshotRow> {
  final String attackId;
  final DateTime capturedAt;
  final double pressureHpa;
  final double pressureDelta24hHpa;
  final double? humidityPercent;
  final double? temperatureCelsius;
  const WeatherSnapshotRow({
    required this.attackId,
    required this.capturedAt,
    required this.pressureHpa,
    required this.pressureDelta24hHpa,
    this.humidityPercent,
    this.temperatureCelsius,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attack_id'] = Variable<String>(attackId);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['pressure_hpa'] = Variable<double>(pressureHpa);
    map['pressure_delta24h_hpa'] = Variable<double>(pressureDelta24hHpa);
    if (!nullToAbsent || humidityPercent != null) {
      map['humidity_percent'] = Variable<double>(humidityPercent);
    }
    if (!nullToAbsent || temperatureCelsius != null) {
      map['temperature_celsius'] = Variable<double>(temperatureCelsius);
    }
    return map;
  }

  WeatherSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return WeatherSnapshotsCompanion(
      attackId: Value(attackId),
      capturedAt: Value(capturedAt),
      pressureHpa: Value(pressureHpa),
      pressureDelta24hHpa: Value(pressureDelta24hHpa),
      humidityPercent: humidityPercent == null && nullToAbsent
          ? const Value.absent()
          : Value(humidityPercent),
      temperatureCelsius: temperatureCelsius == null && nullToAbsent
          ? const Value.absent()
          : Value(temperatureCelsius),
    );
  }

  factory WeatherSnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeatherSnapshotRow(
      attackId: serializer.fromJson<String>(json['attackId']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      pressureHpa: serializer.fromJson<double>(json['pressureHpa']),
      pressureDelta24hHpa: serializer.fromJson<double>(
        json['pressureDelta24hHpa'],
      ),
      humidityPercent: serializer.fromJson<double?>(json['humidityPercent']),
      temperatureCelsius: serializer.fromJson<double?>(
        json['temperatureCelsius'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attackId': serializer.toJson<String>(attackId),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'pressureHpa': serializer.toJson<double>(pressureHpa),
      'pressureDelta24hHpa': serializer.toJson<double>(pressureDelta24hHpa),
      'humidityPercent': serializer.toJson<double?>(humidityPercent),
      'temperatureCelsius': serializer.toJson<double?>(temperatureCelsius),
    };
  }

  WeatherSnapshotRow copyWith({
    String? attackId,
    DateTime? capturedAt,
    double? pressureHpa,
    double? pressureDelta24hHpa,
    Value<double?> humidityPercent = const Value.absent(),
    Value<double?> temperatureCelsius = const Value.absent(),
  }) => WeatherSnapshotRow(
    attackId: attackId ?? this.attackId,
    capturedAt: capturedAt ?? this.capturedAt,
    pressureHpa: pressureHpa ?? this.pressureHpa,
    pressureDelta24hHpa: pressureDelta24hHpa ?? this.pressureDelta24hHpa,
    humidityPercent: humidityPercent.present
        ? humidityPercent.value
        : this.humidityPercent,
    temperatureCelsius: temperatureCelsius.present
        ? temperatureCelsius.value
        : this.temperatureCelsius,
  );
  WeatherSnapshotRow copyWithCompanion(WeatherSnapshotsCompanion data) {
    return WeatherSnapshotRow(
      attackId: data.attackId.present ? data.attackId.value : this.attackId,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      pressureHpa: data.pressureHpa.present
          ? data.pressureHpa.value
          : this.pressureHpa,
      pressureDelta24hHpa: data.pressureDelta24hHpa.present
          ? data.pressureDelta24hHpa.value
          : this.pressureDelta24hHpa,
      humidityPercent: data.humidityPercent.present
          ? data.humidityPercent.value
          : this.humidityPercent,
      temperatureCelsius: data.temperatureCelsius.present
          ? data.temperatureCelsius.value
          : this.temperatureCelsius,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeatherSnapshotRow(')
          ..write('attackId: $attackId, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('pressureHpa: $pressureHpa, ')
          ..write('pressureDelta24hHpa: $pressureDelta24hHpa, ')
          ..write('humidityPercent: $humidityPercent, ')
          ..write('temperatureCelsius: $temperatureCelsius')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    attackId,
    capturedAt,
    pressureHpa,
    pressureDelta24hHpa,
    humidityPercent,
    temperatureCelsius,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeatherSnapshotRow &&
          other.attackId == this.attackId &&
          other.capturedAt == this.capturedAt &&
          other.pressureHpa == this.pressureHpa &&
          other.pressureDelta24hHpa == this.pressureDelta24hHpa &&
          other.humidityPercent == this.humidityPercent &&
          other.temperatureCelsius == this.temperatureCelsius);
}

class WeatherSnapshotsCompanion extends UpdateCompanion<WeatherSnapshotRow> {
  final Value<String> attackId;
  final Value<DateTime> capturedAt;
  final Value<double> pressureHpa;
  final Value<double> pressureDelta24hHpa;
  final Value<double?> humidityPercent;
  final Value<double?> temperatureCelsius;
  final Value<int> rowid;
  const WeatherSnapshotsCompanion({
    this.attackId = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.pressureHpa = const Value.absent(),
    this.pressureDelta24hHpa = const Value.absent(),
    this.humidityPercent = const Value.absent(),
    this.temperatureCelsius = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeatherSnapshotsCompanion.insert({
    required String attackId,
    required DateTime capturedAt,
    required double pressureHpa,
    required double pressureDelta24hHpa,
    this.humidityPercent = const Value.absent(),
    this.temperatureCelsius = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : attackId = Value(attackId),
       capturedAt = Value(capturedAt),
       pressureHpa = Value(pressureHpa),
       pressureDelta24hHpa = Value(pressureDelta24hHpa);
  static Insertable<WeatherSnapshotRow> custom({
    Expression<String>? attackId,
    Expression<DateTime>? capturedAt,
    Expression<double>? pressureHpa,
    Expression<double>? pressureDelta24hHpa,
    Expression<double>? humidityPercent,
    Expression<double>? temperatureCelsius,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attackId != null) 'attack_id': attackId,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (pressureHpa != null) 'pressure_hpa': pressureHpa,
      if (pressureDelta24hHpa != null)
        'pressure_delta24h_hpa': pressureDelta24hHpa,
      if (humidityPercent != null) 'humidity_percent': humidityPercent,
      if (temperatureCelsius != null) 'temperature_celsius': temperatureCelsius,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeatherSnapshotsCompanion copyWith({
    Value<String>? attackId,
    Value<DateTime>? capturedAt,
    Value<double>? pressureHpa,
    Value<double>? pressureDelta24hHpa,
    Value<double?>? humidityPercent,
    Value<double?>? temperatureCelsius,
    Value<int>? rowid,
  }) {
    return WeatherSnapshotsCompanion(
      attackId: attackId ?? this.attackId,
      capturedAt: capturedAt ?? this.capturedAt,
      pressureHpa: pressureHpa ?? this.pressureHpa,
      pressureDelta24hHpa: pressureDelta24hHpa ?? this.pressureDelta24hHpa,
      humidityPercent: humidityPercent ?? this.humidityPercent,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attackId.present) {
      map['attack_id'] = Variable<String>(attackId.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (pressureHpa.present) {
      map['pressure_hpa'] = Variable<double>(pressureHpa.value);
    }
    if (pressureDelta24hHpa.present) {
      map['pressure_delta24h_hpa'] = Variable<double>(
        pressureDelta24hHpa.value,
      );
    }
    if (humidityPercent.present) {
      map['humidity_percent'] = Variable<double>(humidityPercent.value);
    }
    if (temperatureCelsius.present) {
      map['temperature_celsius'] = Variable<double>(temperatureCelsius.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeatherSnapshotsCompanion(')
          ..write('attackId: $attackId, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('pressureHpa: $pressureHpa, ')
          ..write('pressureDelta24hHpa: $pressureDelta24hHpa, ')
          ..write('humidityPercent: $humidityPercent, ')
          ..write('temperatureCelsius: $temperatureCelsius, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationsTable extends Medications
    with TableInfo<$MedicationsTable, MedicationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $MedicationsTable createAlias(String alias) {
    return $MedicationsTable(attachedDatabase, alias);
  }
}

class MedicationRow extends DataClass implements Insertable<MedicationRow> {
  final String id;
  final String name;
  const MedicationRow({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(id: Value(id), name: Value(name));
  }

  factory MedicationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  MedicationRow copyWith({String? id, String? name}) =>
      MedicationRow(id: id ?? this.id, name: name ?? this.name);
  MedicationRow copyWithCompanion(MedicationsCompanion data) {
    return MedicationRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationRow(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationRow &&
          other.id == this.id &&
          other.name == this.name);
}

class MedicationsCompanion extends UpdateCompanion<MedicationRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> rowid;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationsCompanion.insert({
    required String id,
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<MedicationRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return MedicationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationRemindersTable extends MedicationReminders
    with TableInfo<$MedicationRemindersTable, MedicationReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medications (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _minuteOfDayMeta = const VerificationMeta(
    'minuteOfDay',
  );
  @override
  late final GeneratedColumn<int> minuteOfDay = GeneratedColumn<int>(
    'minute_of_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    minuteOfDay,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationReminderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('minute_of_day')) {
      context.handle(
        _minuteOfDayMeta,
        minuteOfDay.isAcceptableOrUnknown(
          data['minute_of_day']!,
          _minuteOfDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minuteOfDayMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationReminderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      minuteOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute_of_day'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
    );
  }

  @override
  $MedicationRemindersTable createAlias(String alias) {
    return $MedicationRemindersTable(attachedDatabase, alias);
  }
}

class MedicationReminderRow extends DataClass
    implements Insertable<MedicationReminderRow> {
  final String id;
  final String medicationId;

  /// Local time-of-day, stored as minutes past midnight (0–1439).
  final int minuteOfDay;
  final bool enabled;
  const MedicationReminderRow({
    required this.id,
    required this.medicationId,
    required this.minuteOfDay,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['medication_id'] = Variable<String>(medicationId);
    map['minute_of_day'] = Variable<int>(minuteOfDay);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  MedicationRemindersCompanion toCompanion(bool nullToAbsent) {
    return MedicationRemindersCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      minuteOfDay: Value(minuteOfDay),
      enabled: Value(enabled),
    );
  }

  factory MedicationReminderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationReminderRow(
      id: serializer.fromJson<String>(json['id']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      minuteOfDay: serializer.fromJson<int>(json['minuteOfDay']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'medicationId': serializer.toJson<String>(medicationId),
      'minuteOfDay': serializer.toJson<int>(minuteOfDay),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  MedicationReminderRow copyWith({
    String? id,
    String? medicationId,
    int? minuteOfDay,
    bool? enabled,
  }) => MedicationReminderRow(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    minuteOfDay: minuteOfDay ?? this.minuteOfDay,
    enabled: enabled ?? this.enabled,
  );
  MedicationReminderRow copyWithCompanion(MedicationRemindersCompanion data) {
    return MedicationReminderRow(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      minuteOfDay: data.minuteOfDay.present
          ? data.minuteOfDay.value
          : this.minuteOfDay,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationReminderRow(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('minuteOfDay: $minuteOfDay, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, medicationId, minuteOfDay, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationReminderRow &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.minuteOfDay == this.minuteOfDay &&
          other.enabled == this.enabled);
}

class MedicationRemindersCompanion
    extends UpdateCompanion<MedicationReminderRow> {
  final Value<String> id;
  final Value<String> medicationId;
  final Value<int> minuteOfDay;
  final Value<bool> enabled;
  final Value<int> rowid;
  const MedicationRemindersCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.minuteOfDay = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationRemindersCompanion.insert({
    required String id,
    required String medicationId,
    required int minuteOfDay,
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       medicationId = Value(medicationId),
       minuteOfDay = Value(minuteOfDay);
  static Insertable<MedicationReminderRow> custom({
    Expression<String>? id,
    Expression<String>? medicationId,
    Expression<int>? minuteOfDay,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (minuteOfDay != null) 'minute_of_day': minuteOfDay,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationRemindersCompanion copyWith({
    Value<String>? id,
    Value<String>? medicationId,
    Value<int>? minuteOfDay,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return MedicationRemindersCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      minuteOfDay: minuteOfDay ?? this.minuteOfDay,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (minuteOfDay.present) {
      map['minute_of_day'] = Variable<int>(minuteOfDay.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationRemindersCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('minuteOfDay: $minuteOfDay, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AttacksTable attacks = $AttacksTable(this);
  late final $WeatherSnapshotsTable weatherSnapshots = $WeatherSnapshotsTable(
    this,
  );
  late final $MedicationsTable medications = $MedicationsTable(this);
  late final $MedicationRemindersTable medicationReminders =
      $MedicationRemindersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    attacks,
    weatherSnapshots,
    medications,
    medicationReminders,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'attacks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('weather_snapshots', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'medications',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('medication_reminders', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AttacksTableCreateCompanionBuilder =
    AttacksCompanion Function({
      required String id,
      required DateTime startedAt,
      required int intensity,
      required HeadLocation location,
      Value<String?> medicationName,
      Value<List<String>> symptoms,
      Value<List<String>> triggers,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$AttacksTableUpdateCompanionBuilder =
    AttacksCompanion Function({
      Value<String> id,
      Value<DateTime> startedAt,
      Value<int> intensity,
      Value<HeadLocation> location,
      Value<String?> medicationName,
      Value<List<String>> symptoms,
      Value<List<String>> triggers,
      Value<String?> notes,
      Value<int> rowid,
    });

final class $$AttacksTableReferences
    extends BaseReferences<_$AppDatabase, $AttacksTable, AttackRow> {
  $$AttacksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WeatherSnapshotsTable, List<WeatherSnapshotRow>>
  _weatherSnapshotsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.weatherSnapshots,
    aliasName: 'attacks__id__weather_snapshots__attack_id',
  );

  $$WeatherSnapshotsTableProcessedTableManager get weatherSnapshotsRefs {
    final manager = $$WeatherSnapshotsTableTableManager(
      $_db,
      $_db.weatherSnapshots,
    ).filter((f) => f.attackId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _weatherSnapshotsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AttacksTableFilterComposer
    extends Composer<_$AppDatabase, $AttacksTable> {
  $$AttacksTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<HeadLocation, HeadLocation, String>
  get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get symptoms => $composableBuilder(
    column: $table.symptoms,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get triggers => $composableBuilder(
    column: $table.triggers,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> weatherSnapshotsRefs(
    Expression<bool> Function($$WeatherSnapshotsTableFilterComposer f) f,
  ) {
    final $$WeatherSnapshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weatherSnapshots,
      getReferencedColumn: (t) => t.attackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeatherSnapshotsTableFilterComposer(
            $db: $db,
            $table: $db.weatherSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AttacksTableOrderingComposer
    extends Composer<_$AppDatabase, $AttacksTable> {
  $$AttacksTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symptoms => $composableBuilder(
    column: $table.symptoms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get triggers => $composableBuilder(
    column: $table.triggers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttacksTable> {
  $$AttacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get intensity =>
      $composableBuilder(column: $table.intensity, builder: (column) => column);

  GeneratedColumnWithTypeConverter<HeadLocation, String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get symptoms =>
      $composableBuilder(column: $table.symptoms, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get triggers =>
      $composableBuilder(column: $table.triggers, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> weatherSnapshotsRefs<T extends Object>(
    Expression<T> Function($$WeatherSnapshotsTableAnnotationComposer a) f,
  ) {
    final $$WeatherSnapshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weatherSnapshots,
      getReferencedColumn: (t) => t.attackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeatherSnapshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.weatherSnapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AttacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttacksTable,
          AttackRow,
          $$AttacksTableFilterComposer,
          $$AttacksTableOrderingComposer,
          $$AttacksTableAnnotationComposer,
          $$AttacksTableCreateCompanionBuilder,
          $$AttacksTableUpdateCompanionBuilder,
          (AttackRow, $$AttacksTableReferences),
          AttackRow,
          PrefetchHooks Function({bool weatherSnapshotsRefs})
        > {
  $$AttacksTableTableManager(_$AppDatabase db, $AttacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> intensity = const Value.absent(),
                Value<HeadLocation> location = const Value.absent(),
                Value<String?> medicationName = const Value.absent(),
                Value<List<String>> symptoms = const Value.absent(),
                Value<List<String>> triggers = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttacksCompanion(
                id: id,
                startedAt: startedAt,
                intensity: intensity,
                location: location,
                medicationName: medicationName,
                symptoms: symptoms,
                triggers: triggers,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime startedAt,
                required int intensity,
                required HeadLocation location,
                Value<String?> medicationName = const Value.absent(),
                Value<List<String>> symptoms = const Value.absent(),
                Value<List<String>> triggers = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttacksCompanion.insert(
                id: id,
                startedAt: startedAt,
                intensity: intensity,
                location: location,
                medicationName: medicationName,
                symptoms: symptoms,
                triggers: triggers,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttacksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({weatherSnapshotsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (weatherSnapshotsRefs) db.weatherSnapshots,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (weatherSnapshotsRefs)
                    await $_getPrefetchedData<
                      AttackRow,
                      $AttacksTable,
                      WeatherSnapshotRow
                    >(
                      currentTable: table,
                      referencedTable: $$AttacksTableReferences
                          ._weatherSnapshotsRefsTable(db),
                      managerFromTypedResult: (p0) => $$AttacksTableReferences(
                        db,
                        table,
                        p0,
                      ).weatherSnapshotsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.attackId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AttacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttacksTable,
      AttackRow,
      $$AttacksTableFilterComposer,
      $$AttacksTableOrderingComposer,
      $$AttacksTableAnnotationComposer,
      $$AttacksTableCreateCompanionBuilder,
      $$AttacksTableUpdateCompanionBuilder,
      (AttackRow, $$AttacksTableReferences),
      AttackRow,
      PrefetchHooks Function({bool weatherSnapshotsRefs})
    >;
typedef $$WeatherSnapshotsTableCreateCompanionBuilder =
    WeatherSnapshotsCompanion Function({
      required String attackId,
      required DateTime capturedAt,
      required double pressureHpa,
      required double pressureDelta24hHpa,
      Value<double?> humidityPercent,
      Value<double?> temperatureCelsius,
      Value<int> rowid,
    });
typedef $$WeatherSnapshotsTableUpdateCompanionBuilder =
    WeatherSnapshotsCompanion Function({
      Value<String> attackId,
      Value<DateTime> capturedAt,
      Value<double> pressureHpa,
      Value<double> pressureDelta24hHpa,
      Value<double?> humidityPercent,
      Value<double?> temperatureCelsius,
      Value<int> rowid,
    });

final class $$WeatherSnapshotsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $WeatherSnapshotsTable,
          WeatherSnapshotRow
        > {
  $$WeatherSnapshotsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AttacksTable _attackIdTable(_$AppDatabase db) =>
      db.attacks.createAlias('weather_snapshots__attack_id__attacks__id');

  $$AttacksTableProcessedTableManager get attackId {
    final $_column = $_itemColumn<String>('attack_id')!;

    final manager = $$AttacksTableTableManager(
      $_db,
      $_db.attacks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_attackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WeatherSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $WeatherSnapshotsTable> {
  $$WeatherSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pressureHpa => $composableBuilder(
    column: $table.pressureHpa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pressureDelta24hHpa => $composableBuilder(
    column: $table.pressureDelta24hHpa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get humidityPercent => $composableBuilder(
    column: $table.humidityPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperatureCelsius => $composableBuilder(
    column: $table.temperatureCelsius,
    builder: (column) => ColumnFilters(column),
  );

  $$AttacksTableFilterComposer get attackId {
    final $$AttacksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attackId,
      referencedTable: $db.attacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttacksTableFilterComposer(
            $db: $db,
            $table: $db.attacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeatherSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeatherSnapshotsTable> {
  $$WeatherSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pressureHpa => $composableBuilder(
    column: $table.pressureHpa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pressureDelta24hHpa => $composableBuilder(
    column: $table.pressureDelta24hHpa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get humidityPercent => $composableBuilder(
    column: $table.humidityPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperatureCelsius => $composableBuilder(
    column: $table.temperatureCelsius,
    builder: (column) => ColumnOrderings(column),
  );

  $$AttacksTableOrderingComposer get attackId {
    final $$AttacksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attackId,
      referencedTable: $db.attacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttacksTableOrderingComposer(
            $db: $db,
            $table: $db.attacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeatherSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeatherSnapshotsTable> {
  $$WeatherSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pressureHpa => $composableBuilder(
    column: $table.pressureHpa,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pressureDelta24hHpa => $composableBuilder(
    column: $table.pressureDelta24hHpa,
    builder: (column) => column,
  );

  GeneratedColumn<double> get humidityPercent => $composableBuilder(
    column: $table.humidityPercent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperatureCelsius => $composableBuilder(
    column: $table.temperatureCelsius,
    builder: (column) => column,
  );

  $$AttacksTableAnnotationComposer get attackId {
    final $$AttacksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attackId,
      referencedTable: $db.attacks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttacksTableAnnotationComposer(
            $db: $db,
            $table: $db.attacks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeatherSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeatherSnapshotsTable,
          WeatherSnapshotRow,
          $$WeatherSnapshotsTableFilterComposer,
          $$WeatherSnapshotsTableOrderingComposer,
          $$WeatherSnapshotsTableAnnotationComposer,
          $$WeatherSnapshotsTableCreateCompanionBuilder,
          $$WeatherSnapshotsTableUpdateCompanionBuilder,
          (WeatherSnapshotRow, $$WeatherSnapshotsTableReferences),
          WeatherSnapshotRow,
          PrefetchHooks Function({bool attackId})
        > {
  $$WeatherSnapshotsTableTableManager(
    _$AppDatabase db,
    $WeatherSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeatherSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeatherSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeatherSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> attackId = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<double> pressureHpa = const Value.absent(),
                Value<double> pressureDelta24hHpa = const Value.absent(),
                Value<double?> humidityPercent = const Value.absent(),
                Value<double?> temperatureCelsius = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeatherSnapshotsCompanion(
                attackId: attackId,
                capturedAt: capturedAt,
                pressureHpa: pressureHpa,
                pressureDelta24hHpa: pressureDelta24hHpa,
                humidityPercent: humidityPercent,
                temperatureCelsius: temperatureCelsius,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String attackId,
                required DateTime capturedAt,
                required double pressureHpa,
                required double pressureDelta24hHpa,
                Value<double?> humidityPercent = const Value.absent(),
                Value<double?> temperatureCelsius = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeatherSnapshotsCompanion.insert(
                attackId: attackId,
                capturedAt: capturedAt,
                pressureHpa: pressureHpa,
                pressureDelta24hHpa: pressureDelta24hHpa,
                humidityPercent: humidityPercent,
                temperatureCelsius: temperatureCelsius,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WeatherSnapshotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({attackId = false}) {
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
                    if (attackId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.attackId,
                                referencedTable:
                                    $$WeatherSnapshotsTableReferences
                                        ._attackIdTable(db),
                                referencedColumn:
                                    $$WeatherSnapshotsTableReferences
                                        ._attackIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$WeatherSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeatherSnapshotsTable,
      WeatherSnapshotRow,
      $$WeatherSnapshotsTableFilterComposer,
      $$WeatherSnapshotsTableOrderingComposer,
      $$WeatherSnapshotsTableAnnotationComposer,
      $$WeatherSnapshotsTableCreateCompanionBuilder,
      $$WeatherSnapshotsTableUpdateCompanionBuilder,
      (WeatherSnapshotRow, $$WeatherSnapshotsTableReferences),
      WeatherSnapshotRow,
      PrefetchHooks Function({bool attackId})
    >;
typedef $$MedicationsTableCreateCompanionBuilder =
    MedicationsCompanion Function({
      required String id,
      required String name,
      Value<int> rowid,
    });
typedef $$MedicationsTableUpdateCompanionBuilder =
    MedicationsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> rowid,
    });

final class $$MedicationsTableReferences
    extends BaseReferences<_$AppDatabase, $MedicationsTable, MedicationRow> {
  $$MedicationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $MedicationRemindersTable,
    List<MedicationReminderRow>
  >
  _medicationRemindersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.medicationReminders,
        aliasName: 'medications__id__medication_reminders__medication_id',
      );

  $$MedicationRemindersTableProcessedTableManager get medicationRemindersRefs {
    final manager = $$MedicationRemindersTableTableManager(
      $_db,
      $_db.medicationReminders,
    ).filter((f) => f.medicationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _medicationRemindersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MedicationsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> medicationRemindersRefs(
    Expression<bool> Function($$MedicationRemindersTableFilterComposer f) f,
  ) {
    final $$MedicationRemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medicationReminders,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationRemindersTableFilterComposer(
            $db: $db,
            $table: $db.medicationReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MedicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> medicationRemindersRefs<T extends Object>(
    Expression<T> Function($$MedicationRemindersTableAnnotationComposer a) f,
  ) {
    final $$MedicationRemindersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.medicationReminders,
          getReferencedColumn: (t) => t.medicationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MedicationRemindersTableAnnotationComposer(
                $db: $db,
                $table: $db.medicationReminders,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MedicationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationsTable,
          MedicationRow,
          $$MedicationsTableFilterComposer,
          $$MedicationsTableOrderingComposer,
          $$MedicationsTableAnnotationComposer,
          $$MedicationsTableCreateCompanionBuilder,
          $$MedicationsTableUpdateCompanionBuilder,
          (MedicationRow, $$MedicationsTableReferences),
          MedicationRow,
          PrefetchHooks Function({bool medicationRemindersRefs})
        > {
  $$MedicationsTableTableManager(_$AppDatabase db, $MedicationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion(id: id, name: name, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) =>
                  MedicationsCompanion.insert(id: id, name: name, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MedicationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({medicationRemindersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (medicationRemindersRefs) db.medicationReminders,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (medicationRemindersRefs)
                    await $_getPrefetchedData<
                      MedicationRow,
                      $MedicationsTable,
                      MedicationReminderRow
                    >(
                      currentTable: table,
                      referencedTable: $$MedicationsTableReferences
                          ._medicationRemindersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MedicationsTableReferences(
                            db,
                            table,
                            p0,
                          ).medicationRemindersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.medicationId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MedicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationsTable,
      MedicationRow,
      $$MedicationsTableFilterComposer,
      $$MedicationsTableOrderingComposer,
      $$MedicationsTableAnnotationComposer,
      $$MedicationsTableCreateCompanionBuilder,
      $$MedicationsTableUpdateCompanionBuilder,
      (MedicationRow, $$MedicationsTableReferences),
      MedicationRow,
      PrefetchHooks Function({bool medicationRemindersRefs})
    >;
typedef $$MedicationRemindersTableCreateCompanionBuilder =
    MedicationRemindersCompanion Function({
      required String id,
      required String medicationId,
      required int minuteOfDay,
      Value<bool> enabled,
      Value<int> rowid,
    });
typedef $$MedicationRemindersTableUpdateCompanionBuilder =
    MedicationRemindersCompanion Function({
      Value<String> id,
      Value<String> medicationId,
      Value<int> minuteOfDay,
      Value<bool> enabled,
      Value<int> rowid,
    });

final class $$MedicationRemindersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MedicationRemindersTable,
          MedicationReminderRow
        > {
  $$MedicationRemindersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MedicationsTable _medicationIdTable(_$AppDatabase db) => db
      .medications
      .createAlias('medication_reminders__medication_id__medications__id');

  $$MedicationsTableProcessedTableManager get medicationId {
    final $_column = $_itemColumn<String>('medication_id')!;

    final manager = $$MedicationsTableTableManager(
      $_db,
      $_db.medications,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_medicationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MedicationRemindersTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationRemindersTable> {
  $$MedicationRemindersTableFilterComposer({
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

  ColumnFilters<int> get minuteOfDay => $composableBuilder(
    column: $table.minuteOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  $$MedicationsTableFilterComposer get medicationId {
    final $$MedicationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableFilterComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MedicationRemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationRemindersTable> {
  $$MedicationRemindersTableOrderingComposer({
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

  ColumnOrderings<int> get minuteOfDay => $composableBuilder(
    column: $table.minuteOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  $$MedicationsTableOrderingComposer get medicationId {
    final $$MedicationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableOrderingComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MedicationRemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationRemindersTable> {
  $$MedicationRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get minuteOfDay => $composableBuilder(
    column: $table.minuteOfDay,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  $$MedicationsTableAnnotationComposer get medicationId {
    final $$MedicationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableAnnotationComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MedicationRemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationRemindersTable,
          MedicationReminderRow,
          $$MedicationRemindersTableFilterComposer,
          $$MedicationRemindersTableOrderingComposer,
          $$MedicationRemindersTableAnnotationComposer,
          $$MedicationRemindersTableCreateCompanionBuilder,
          $$MedicationRemindersTableUpdateCompanionBuilder,
          (MedicationReminderRow, $$MedicationRemindersTableReferences),
          MedicationReminderRow,
          PrefetchHooks Function({bool medicationId})
        > {
  $$MedicationRemindersTableTableManager(
    _$AppDatabase db,
    $MedicationRemindersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationRemindersTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MedicationRemindersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<int> minuteOfDay = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationRemindersCompanion(
                id: id,
                medicationId: medicationId,
                minuteOfDay: minuteOfDay,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String medicationId,
                required int minuteOfDay,
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationRemindersCompanion.insert(
                id: id,
                medicationId: medicationId,
                minuteOfDay: minuteOfDay,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MedicationRemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({medicationId = false}) {
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
                    if (medicationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.medicationId,
                                referencedTable:
                                    $$MedicationRemindersTableReferences
                                        ._medicationIdTable(db),
                                referencedColumn:
                                    $$MedicationRemindersTableReferences
                                        ._medicationIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$MedicationRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationRemindersTable,
      MedicationReminderRow,
      $$MedicationRemindersTableFilterComposer,
      $$MedicationRemindersTableOrderingComposer,
      $$MedicationRemindersTableAnnotationComposer,
      $$MedicationRemindersTableCreateCompanionBuilder,
      $$MedicationRemindersTableUpdateCompanionBuilder,
      (MedicationReminderRow, $$MedicationRemindersTableReferences),
      MedicationReminderRow,
      PrefetchHooks Function({bool medicationId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AttacksTableTableManager get attacks =>
      $$AttacksTableTableManager(_db, _db.attacks);
  $$WeatherSnapshotsTableTableManager get weatherSnapshots =>
      $$WeatherSnapshotsTableTableManager(_db, _db.weatherSnapshots);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db, _db.medications);
  $$MedicationRemindersTableTableManager get medicationReminders =>
      $$MedicationRemindersTableTableManager(_db, _db.medicationReminders);
}
