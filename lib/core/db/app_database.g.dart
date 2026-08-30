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
  late final GeneratedColumnWithTypeConverter<List<HeadRegion>, String>
  regions = GeneratedColumn<String>(
    'regions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<List<HeadRegion>>($AttacksTable.$converterregions);
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
  late final GeneratedColumnWithTypeConverter<ExertionLevel?, String>
  exertionLevel = GeneratedColumn<String>(
    'exertion_level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<ExertionLevel?>($AttacksTable.$converterexertionLeveln);
  @override
  late final GeneratedColumnWithTypeConverter<MedicationEffect?, String>
  medicationEffect = GeneratedColumn<String>(
    'medication_effect',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<MedicationEffect?>($AttacksTable.$convertermedicationEffectn);
  @override
  late final GeneratedColumnWithTypeConverter<List<AuraType>?, String> aura =
      GeneratedColumn<String>(
        'aura',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<List<AuraType>?>($AttacksTable.$converterauran);
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
    'steps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncedRevisionMeta = const VerificationMeta(
    'syncedRevision',
  );
  @override
  late final GeneratedColumn<int> syncedRevision = GeneratedColumn<int>(
    'synced_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    intensity,
    regions,
    medicationName,
    symptoms,
    triggers,
    notes,
    exertionLevel,
    medicationEffect,
    aura,
    endedAt,
    steps,
    updatedAt,
    revision,
    syncedRevision,
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
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('synced_revision')) {
      context.handle(
        _syncedRevisionMeta,
        syncedRevision.isAcceptableOrUnknown(
          data['synced_revision']!,
          _syncedRevisionMeta,
        ),
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
      regions: $AttacksTable.$converterregions.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}regions'],
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
      exertionLevel: $AttacksTable.$converterexertionLeveln.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}exertion_level'],
        ),
      ),
      medicationEffect: $AttacksTable.$convertermedicationEffectn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}medication_effect'],
        ),
      ),
      aura: $AttacksTable.$converterauran.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}aura'],
        ),
      ),
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}steps'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      syncedRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_revision'],
      ),
    );
  }

  @override
  $AttacksTable createAlias(String alias) {
    return $AttacksTable(attachedDatabase, alias);
  }

  static TypeConverter<List<HeadRegion>, String> $converterregions =
      const HeadRegionListConverter();
  static TypeConverter<List<String>, String> $convertersymptoms =
      const StringListConverter();
  static TypeConverter<List<String>, String> $convertertriggers =
      const StringListConverter();
  static JsonTypeConverter2<ExertionLevel, String, String>
  $converterexertionLevel = const EnumNameConverter<ExertionLevel>(
    ExertionLevel.values,
  );
  static JsonTypeConverter2<ExertionLevel?, String?, String?>
  $converterexertionLeveln = JsonTypeConverter2.asNullable(
    $converterexertionLevel,
  );
  static JsonTypeConverter2<MedicationEffect, String, String>
  $convertermedicationEffect = const EnumNameConverter<MedicationEffect>(
    MedicationEffect.values,
  );
  static JsonTypeConverter2<MedicationEffect?, String?, String?>
  $convertermedicationEffectn = JsonTypeConverter2.asNullable(
    $convertermedicationEffect,
  );
  static TypeConverter<List<AuraType>, String> $converteraura =
      const AuraTypeListConverter();
  static TypeConverter<List<AuraType>?, String?> $converterauran =
      NullAwareTypeConverter.wrap($converteraura);
}

class AttackRow extends DataClass implements Insertable<AttackRow> {
  final String id;

  /// Stored as UTC unix timestamp.
  final DateTime startedAt;
  final int intensity;

  /// Every head area the user tapped, JSON-encoded.
  final List<HeadRegion> regions;
  final String? medicationName;
  final List<String> symptoms;
  final List<String> triggers;
  final String? notes;
  final ExertionLevel? exertionLevel;

  /// Whether the medication helped. Null is "never answered", which also covers every attack where nothing was taken.
  final MedicationEffect? medicationEffect;

  /// Aura kinds reported for this attack, JSON-encoded.
  final List<AuraType>? aura;

  /// When the attack stopped, UTC. Null is "still going, or never said" — one state on purpose, since nothing here can tell those apart.
  final DateTime? endedAt;

  /// Steps that day up to the log, from Apple Health. Nullable because the source is optional in every sense: not iOS, not granted, or no samples.
  final int? steps;

  /// Wall clock of the last local mutation, used only to settle which of two devices' versions wins.
  final DateTime? updatedAt;

  /// Bumped on every local mutation.
  final int revision;

  /// The [revision] the server confirmed. Dirty is `syncedRevision != revision`, so a clock stepping backwards cannot hide an edit either.
  final int? syncedRevision;
  const AttackRow({
    required this.id,
    required this.startedAt,
    required this.intensity,
    required this.regions,
    this.medicationName,
    required this.symptoms,
    required this.triggers,
    this.notes,
    this.exertionLevel,
    this.medicationEffect,
    this.aura,
    this.endedAt,
    this.steps,
    this.updatedAt,
    required this.revision,
    this.syncedRevision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['intensity'] = Variable<int>(intensity);
    {
      map['regions'] = Variable<String>(
        $AttacksTable.$converterregions.toSql(regions),
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
    if (!nullToAbsent || exertionLevel != null) {
      map['exertion_level'] = Variable<String>(
        $AttacksTable.$converterexertionLeveln.toSql(exertionLevel),
      );
    }
    if (!nullToAbsent || medicationEffect != null) {
      map['medication_effect'] = Variable<String>(
        $AttacksTable.$convertermedicationEffectn.toSql(medicationEffect),
      );
    }
    if (!nullToAbsent || aura != null) {
      map['aura'] = Variable<String>($AttacksTable.$converterauran.toSql(aura));
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || steps != null) {
      map['steps'] = Variable<int>(steps);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['revision'] = Variable<int>(revision);
    if (!nullToAbsent || syncedRevision != null) {
      map['synced_revision'] = Variable<int>(syncedRevision);
    }
    return map;
  }

  AttacksCompanion toCompanion(bool nullToAbsent) {
    return AttacksCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      intensity: Value(intensity),
      regions: Value(regions),
      medicationName: medicationName == null && nullToAbsent
          ? const Value.absent()
          : Value(medicationName),
      symptoms: Value(symptoms),
      triggers: Value(triggers),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      exertionLevel: exertionLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(exertionLevel),
      medicationEffect: medicationEffect == null && nullToAbsent
          ? const Value.absent()
          : Value(medicationEffect),
      aura: aura == null && nullToAbsent ? const Value.absent() : Value(aura),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      steps: steps == null && nullToAbsent
          ? const Value.absent()
          : Value(steps),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      revision: Value(revision),
      syncedRevision: syncedRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedRevision),
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
      regions: serializer.fromJson<List<HeadRegion>>(json['regions']),
      medicationName: serializer.fromJson<String?>(json['medicationName']),
      symptoms: serializer.fromJson<List<String>>(json['symptoms']),
      triggers: serializer.fromJson<List<String>>(json['triggers']),
      notes: serializer.fromJson<String?>(json['notes']),
      exertionLevel: $AttacksTable.$converterexertionLeveln.fromJson(
        serializer.fromJson<String?>(json['exertionLevel']),
      ),
      medicationEffect: $AttacksTable.$convertermedicationEffectn.fromJson(
        serializer.fromJson<String?>(json['medicationEffect']),
      ),
      aura: serializer.fromJson<List<AuraType>?>(json['aura']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      steps: serializer.fromJson<int?>(json['steps']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      revision: serializer.fromJson<int>(json['revision']),
      syncedRevision: serializer.fromJson<int?>(json['syncedRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'intensity': serializer.toJson<int>(intensity),
      'regions': serializer.toJson<List<HeadRegion>>(regions),
      'medicationName': serializer.toJson<String?>(medicationName),
      'symptoms': serializer.toJson<List<String>>(symptoms),
      'triggers': serializer.toJson<List<String>>(triggers),
      'notes': serializer.toJson<String?>(notes),
      'exertionLevel': serializer.toJson<String?>(
        $AttacksTable.$converterexertionLeveln.toJson(exertionLevel),
      ),
      'medicationEffect': serializer.toJson<String?>(
        $AttacksTable.$convertermedicationEffectn.toJson(medicationEffect),
      ),
      'aura': serializer.toJson<List<AuraType>?>(aura),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'steps': serializer.toJson<int?>(steps),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'revision': serializer.toJson<int>(revision),
      'syncedRevision': serializer.toJson<int?>(syncedRevision),
    };
  }

  AttackRow copyWith({
    String? id,
    DateTime? startedAt,
    int? intensity,
    List<HeadRegion>? regions,
    Value<String?> medicationName = const Value.absent(),
    List<String>? symptoms,
    List<String>? triggers,
    Value<String?> notes = const Value.absent(),
    Value<ExertionLevel?> exertionLevel = const Value.absent(),
    Value<MedicationEffect?> medicationEffect = const Value.absent(),
    Value<List<AuraType>?> aura = const Value.absent(),
    Value<DateTime?> endedAt = const Value.absent(),
    Value<int?> steps = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    int? revision,
    Value<int?> syncedRevision = const Value.absent(),
  }) => AttackRow(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    intensity: intensity ?? this.intensity,
    regions: regions ?? this.regions,
    medicationName: medicationName.present
        ? medicationName.value
        : this.medicationName,
    symptoms: symptoms ?? this.symptoms,
    triggers: triggers ?? this.triggers,
    notes: notes.present ? notes.value : this.notes,
    exertionLevel: exertionLevel.present
        ? exertionLevel.value
        : this.exertionLevel,
    medicationEffect: medicationEffect.present
        ? medicationEffect.value
        : this.medicationEffect,
    aura: aura.present ? aura.value : this.aura,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    steps: steps.present ? steps.value : this.steps,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    revision: revision ?? this.revision,
    syncedRevision: syncedRevision.present
        ? syncedRevision.value
        : this.syncedRevision,
  );
  AttackRow copyWithCompanion(AttacksCompanion data) {
    return AttackRow(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      intensity: data.intensity.present ? data.intensity.value : this.intensity,
      regions: data.regions.present ? data.regions.value : this.regions,
      medicationName: data.medicationName.present
          ? data.medicationName.value
          : this.medicationName,
      symptoms: data.symptoms.present ? data.symptoms.value : this.symptoms,
      triggers: data.triggers.present ? data.triggers.value : this.triggers,
      notes: data.notes.present ? data.notes.value : this.notes,
      exertionLevel: data.exertionLevel.present
          ? data.exertionLevel.value
          : this.exertionLevel,
      medicationEffect: data.medicationEffect.present
          ? data.medicationEffect.value
          : this.medicationEffect,
      aura: data.aura.present ? data.aura.value : this.aura,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      steps: data.steps.present ? data.steps.value : this.steps,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
      syncedRevision: data.syncedRevision.present
          ? data.syncedRevision.value
          : this.syncedRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttackRow(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('intensity: $intensity, ')
          ..write('regions: $regions, ')
          ..write('medicationName: $medicationName, ')
          ..write('symptoms: $symptoms, ')
          ..write('triggers: $triggers, ')
          ..write('notes: $notes, ')
          ..write('exertionLevel: $exertionLevel, ')
          ..write('medicationEffect: $medicationEffect, ')
          ..write('aura: $aura, ')
          ..write('endedAt: $endedAt, ')
          ..write('steps: $steps, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('syncedRevision: $syncedRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    intensity,
    regions,
    medicationName,
    symptoms,
    triggers,
    notes,
    exertionLevel,
    medicationEffect,
    aura,
    endedAt,
    steps,
    updatedAt,
    revision,
    syncedRevision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttackRow &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.intensity == this.intensity &&
          other.regions == this.regions &&
          other.medicationName == this.medicationName &&
          other.symptoms == this.symptoms &&
          other.triggers == this.triggers &&
          other.notes == this.notes &&
          other.exertionLevel == this.exertionLevel &&
          other.medicationEffect == this.medicationEffect &&
          other.aura == this.aura &&
          other.endedAt == this.endedAt &&
          other.steps == this.steps &&
          other.updatedAt == this.updatedAt &&
          other.revision == this.revision &&
          other.syncedRevision == this.syncedRevision);
}

class AttacksCompanion extends UpdateCompanion<AttackRow> {
  final Value<String> id;
  final Value<DateTime> startedAt;
  final Value<int> intensity;
  final Value<List<HeadRegion>> regions;
  final Value<String?> medicationName;
  final Value<List<String>> symptoms;
  final Value<List<String>> triggers;
  final Value<String?> notes;
  final Value<ExertionLevel?> exertionLevel;
  final Value<MedicationEffect?> medicationEffect;
  final Value<List<AuraType>?> aura;
  final Value<DateTime?> endedAt;
  final Value<int?> steps;
  final Value<DateTime?> updatedAt;
  final Value<int> revision;
  final Value<int?> syncedRevision;
  final Value<int> rowid;
  const AttacksCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.intensity = const Value.absent(),
    this.regions = const Value.absent(),
    this.medicationName = const Value.absent(),
    this.symptoms = const Value.absent(),
    this.triggers = const Value.absent(),
    this.notes = const Value.absent(),
    this.exertionLevel = const Value.absent(),
    this.medicationEffect = const Value.absent(),
    this.aura = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.steps = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.syncedRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttacksCompanion.insert({
    required String id,
    required DateTime startedAt,
    required int intensity,
    this.regions = const Value.absent(),
    this.medicationName = const Value.absent(),
    this.symptoms = const Value.absent(),
    this.triggers = const Value.absent(),
    this.notes = const Value.absent(),
    this.exertionLevel = const Value.absent(),
    this.medicationEffect = const Value.absent(),
    this.aura = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.steps = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.syncedRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt),
       intensity = Value(intensity);
  static Insertable<AttackRow> custom({
    Expression<String>? id,
    Expression<DateTime>? startedAt,
    Expression<int>? intensity,
    Expression<String>? regions,
    Expression<String>? medicationName,
    Expression<String>? symptoms,
    Expression<String>? triggers,
    Expression<String>? notes,
    Expression<String>? exertionLevel,
    Expression<String>? medicationEffect,
    Expression<String>? aura,
    Expression<DateTime>? endedAt,
    Expression<int>? steps,
    Expression<DateTime>? updatedAt,
    Expression<int>? revision,
    Expression<int>? syncedRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (intensity != null) 'intensity': intensity,
      if (regions != null) 'regions': regions,
      if (medicationName != null) 'medication_name': medicationName,
      if (symptoms != null) 'symptoms': symptoms,
      if (triggers != null) 'triggers': triggers,
      if (notes != null) 'notes': notes,
      if (exertionLevel != null) 'exertion_level': exertionLevel,
      if (medicationEffect != null) 'medication_effect': medicationEffect,
      if (aura != null) 'aura': aura,
      if (endedAt != null) 'ended_at': endedAt,
      if (steps != null) 'steps': steps,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (revision != null) 'revision': revision,
      if (syncedRevision != null) 'synced_revision': syncedRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttacksCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? startedAt,
    Value<int>? intensity,
    Value<List<HeadRegion>>? regions,
    Value<String?>? medicationName,
    Value<List<String>>? symptoms,
    Value<List<String>>? triggers,
    Value<String?>? notes,
    Value<ExertionLevel?>? exertionLevel,
    Value<MedicationEffect?>? medicationEffect,
    Value<List<AuraType>?>? aura,
    Value<DateTime?>? endedAt,
    Value<int?>? steps,
    Value<DateTime?>? updatedAt,
    Value<int>? revision,
    Value<int?>? syncedRevision,
    Value<int>? rowid,
  }) {
    return AttacksCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      intensity: intensity ?? this.intensity,
      regions: regions ?? this.regions,
      medicationName: medicationName ?? this.medicationName,
      symptoms: symptoms ?? this.symptoms,
      triggers: triggers ?? this.triggers,
      notes: notes ?? this.notes,
      exertionLevel: exertionLevel ?? this.exertionLevel,
      medicationEffect: medicationEffect ?? this.medicationEffect,
      aura: aura ?? this.aura,
      endedAt: endedAt ?? this.endedAt,
      steps: steps ?? this.steps,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      syncedRevision: syncedRevision ?? this.syncedRevision,
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
    if (regions.present) {
      map['regions'] = Variable<String>(
        $AttacksTable.$converterregions.toSql(regions.value),
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
    if (exertionLevel.present) {
      map['exertion_level'] = Variable<String>(
        $AttacksTable.$converterexertionLeveln.toSql(exertionLevel.value),
      );
    }
    if (medicationEffect.present) {
      map['medication_effect'] = Variable<String>(
        $AttacksTable.$convertermedicationEffectn.toSql(medicationEffect.value),
      );
    }
    if (aura.present) {
      map['aura'] = Variable<String>(
        $AttacksTable.$converterauran.toSql(aura.value),
      );
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (syncedRevision.present) {
      map['synced_revision'] = Variable<int>(syncedRevision.value);
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
          ..write('regions: $regions, ')
          ..write('medicationName: $medicationName, ')
          ..write('symptoms: $symptoms, ')
          ..write('triggers: $triggers, ')
          ..write('notes: $notes, ')
          ..write('exertionLevel: $exertionLevel, ')
          ..write('medicationEffect: $medicationEffect, ')
          ..write('aura: $aura, ')
          ..write('endedAt: $endedAt, ')
          ..write('steps: $steps, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('syncedRevision: $syncedRevision, ')
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncedRevisionMeta = const VerificationMeta(
    'syncedRevision',
  );
  @override
  late final GeneratedColumn<int> syncedRevision = GeneratedColumn<int>(
    'synced_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    createdAt,
    updatedAt,
    revision,
    syncedRevision,
  ];
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('synced_revision')) {
      context.handle(
        _syncedRevisionMeta,
        syncedRevision.isAcceptableOrUnknown(
          data['synced_revision']!,
          _syncedRevisionMeta,
        ),
      );
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
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      syncedRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_revision'],
      ),
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

  /// When the user saved this medication (UTC).
  final DateTime? createdAt;

  /// Sync state, added in v7.
  final DateTime? updatedAt;
  final int revision;
  final int? syncedRevision;
  const MedicationRow({
    required this.id,
    required this.name,
    this.createdAt,
    this.updatedAt,
    required this.revision,
    this.syncedRevision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['revision'] = Variable<int>(revision);
    if (!nullToAbsent || syncedRevision != null) {
      map['synced_revision'] = Variable<int>(syncedRevision);
    }
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      revision: Value(revision),
      syncedRevision: syncedRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedRevision),
    );
  }

  factory MedicationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      revision: serializer.fromJson<int>(json['revision']),
      syncedRevision: serializer.fromJson<int?>(json['syncedRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'revision': serializer.toJson<int>(revision),
      'syncedRevision': serializer.toJson<int?>(syncedRevision),
    };
  }

  MedicationRow copyWith({
    String? id,
    String? name,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    int? revision,
    Value<int?> syncedRevision = const Value.absent(),
  }) => MedicationRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    revision: revision ?? this.revision,
    syncedRevision: syncedRevision.present
        ? syncedRevision.value
        : this.syncedRevision,
  );
  MedicationRow copyWithCompanion(MedicationsCompanion data) {
    return MedicationRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
      syncedRevision: data.syncedRevision.present
          ? data.syncedRevision.value
          : this.syncedRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('syncedRevision: $syncedRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, createdAt, updatedAt, revision, syncedRevision);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.revision == this.revision &&
          other.syncedRevision == this.syncedRevision);
}

class MedicationsCompanion extends UpdateCompanion<MedicationRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> revision;
  final Value<int?> syncedRevision;
  final Value<int> rowid;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.syncedRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationsCompanion.insert({
    required String id,
    required String name,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.syncedRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<MedicationRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? revision,
    Expression<int>? syncedRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (revision != null) 'revision': revision,
      if (syncedRevision != null) 'synced_revision': syncedRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? revision,
    Value<int?>? syncedRevision,
    Value<int>? rowid,
  }) {
    return MedicationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      syncedRevision: syncedRevision ?? this.syncedRevision,
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
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (syncedRevision.present) {
      map['synced_revision'] = Variable<int>(syncedRevision.value);
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
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('syncedRevision: $syncedRevision, ')
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncedRevisionMeta = const VerificationMeta(
    'syncedRevision',
  );
  @override
  late final GeneratedColumn<int> syncedRevision = GeneratedColumn<int>(
    'synced_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    minuteOfDay,
    enabled,
    createdAt,
    updatedAt,
    revision,
    syncedRevision,
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('synced_revision')) {
      context.handle(
        _syncedRevisionMeta,
        syncedRevision.isAcceptableOrUnknown(
          data['synced_revision']!,
          _syncedRevisionMeta,
        ),
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
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      syncedRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_revision'],
      ),
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

  /// When this reminder was created (UTC).
  final DateTime? createdAt;

  /// Sync state, added in v7.
  final DateTime? updatedAt;
  final int revision;
  final int? syncedRevision;
  const MedicationReminderRow({
    required this.id,
    required this.medicationId,
    required this.minuteOfDay,
    required this.enabled,
    this.createdAt,
    this.updatedAt,
    required this.revision,
    this.syncedRevision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['medication_id'] = Variable<String>(medicationId);
    map['minute_of_day'] = Variable<int>(minuteOfDay);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['revision'] = Variable<int>(revision);
    if (!nullToAbsent || syncedRevision != null) {
      map['synced_revision'] = Variable<int>(syncedRevision);
    }
    return map;
  }

  MedicationRemindersCompanion toCompanion(bool nullToAbsent) {
    return MedicationRemindersCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      minuteOfDay: Value(minuteOfDay),
      enabled: Value(enabled),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      revision: Value(revision),
      syncedRevision: syncedRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedRevision),
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
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      revision: serializer.fromJson<int>(json['revision']),
      syncedRevision: serializer.fromJson<int?>(json['syncedRevision']),
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
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'revision': serializer.toJson<int>(revision),
      'syncedRevision': serializer.toJson<int?>(syncedRevision),
    };
  }

  MedicationReminderRow copyWith({
    String? id,
    String? medicationId,
    int? minuteOfDay,
    bool? enabled,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    int? revision,
    Value<int?> syncedRevision = const Value.absent(),
  }) => MedicationReminderRow(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    minuteOfDay: minuteOfDay ?? this.minuteOfDay,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    revision: revision ?? this.revision,
    syncedRevision: syncedRevision.present
        ? syncedRevision.value
        : this.syncedRevision,
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
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
      syncedRevision: data.syncedRevision.present
          ? data.syncedRevision.value
          : this.syncedRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationReminderRow(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('minuteOfDay: $minuteOfDay, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('syncedRevision: $syncedRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    medicationId,
    minuteOfDay,
    enabled,
    createdAt,
    updatedAt,
    revision,
    syncedRevision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationReminderRow &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.minuteOfDay == this.minuteOfDay &&
          other.enabled == this.enabled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.revision == this.revision &&
          other.syncedRevision == this.syncedRevision);
}

class MedicationRemindersCompanion
    extends UpdateCompanion<MedicationReminderRow> {
  final Value<String> id;
  final Value<String> medicationId;
  final Value<int> minuteOfDay;
  final Value<bool> enabled;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> revision;
  final Value<int?> syncedRevision;
  final Value<int> rowid;
  const MedicationRemindersCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.minuteOfDay = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.syncedRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationRemindersCompanion.insert({
    required String id,
    required String medicationId,
    required int minuteOfDay,
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.syncedRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       medicationId = Value(medicationId),
       minuteOfDay = Value(minuteOfDay);
  static Insertable<MedicationReminderRow> custom({
    Expression<String>? id,
    Expression<String>? medicationId,
    Expression<int>? minuteOfDay,
    Expression<bool>? enabled,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? revision,
    Expression<int>? syncedRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (minuteOfDay != null) 'minute_of_day': minuteOfDay,
      if (enabled != null) 'enabled': enabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (revision != null) 'revision': revision,
      if (syncedRevision != null) 'synced_revision': syncedRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationRemindersCompanion copyWith({
    Value<String>? id,
    Value<String>? medicationId,
    Value<int>? minuteOfDay,
    Value<bool>? enabled,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? revision,
    Value<int?>? syncedRevision,
    Value<int>? rowid,
  }) {
    return MedicationRemindersCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      minuteOfDay: minuteOfDay ?? this.minuteOfDay,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      syncedRevision: syncedRevision ?? this.syncedRevision,
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
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (syncedRevision.present) {
      map['synced_revision'] = Variable<int>(syncedRevision.value);
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
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('syncedRevision: $syncedRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppNotificationsTable extends AppNotifications
    with TableInfo<$AppNotificationsTable, AppNotificationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<NotificationType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<NotificationType>($AppNotificationsTable.$convertertype);
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
    'read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderIdMeta = const VerificationMeta(
    'reminderId',
  );
  @override
  late final GeneratedColumn<String> reminderId = GeneratedColumn<String>(
    'reminder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pressureDropHpaMeta = const VerificationMeta(
    'pressureDropHpa',
  );
  @override
  late final GeneratedColumn<double> pressureDropHpa = GeneratedColumn<double>(
    'pressure_drop_hpa',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncedRevisionMeta = const VerificationMeta(
    'syncedRevision',
  );
  @override
  late final GeneratedColumn<int> syncedRevision = GeneratedColumn<int>(
    'synced_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    occurredAt,
    readAt,
    medicationId,
    reminderId,
    pressureDropHpa,
    updatedAt,
    revision,
    syncedRevision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppNotificationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    }
    if (data.containsKey('reminder_id')) {
      context.handle(
        _reminderIdMeta,
        reminderId.isAcceptableOrUnknown(data['reminder_id']!, _reminderIdMeta),
      );
    }
    if (data.containsKey('pressure_drop_hpa')) {
      context.handle(
        _pressureDropHpaMeta,
        pressureDropHpa.isAcceptableOrUnknown(
          data['pressure_drop_hpa']!,
          _pressureDropHpaMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('synced_revision')) {
      context.handle(
        _syncedRevisionMeta,
        syncedRevision.isAcceptableOrUnknown(
          data['synced_revision']!,
          _syncedRevisionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppNotificationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppNotificationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: $AppNotificationsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}read_at'],
      ),
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      ),
      reminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_id'],
      ),
      pressureDropHpa: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pressure_drop_hpa'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      syncedRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_revision'],
      ),
    );
  }

  @override
  $AppNotificationsTable createAlias(String alias) {
    return $AppNotificationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<NotificationType, String, String> $convertertype =
      const EnumNameConverter<NotificationType>(NotificationType.values);
}

class AppNotificationRow extends DataClass
    implements Insertable<AppNotificationRow> {
  /// Derived: `rem:<reminderId>:<epochMinute>` or `pa:<eventId>`.
  final String id;
  final NotificationType type;

  /// When it fired (UTC).
  final DateTime occurredAt;

  /// Null while unread. Syncs like everything else, so reading on one device clears the badge on the others.
  final DateTime? readAt;

  /// No `references` on purpose, unlike `MedicationReminders.medicationId`.
  final String? medicationId;
  final String? reminderId;
  final double? pressureDropHpa;

  /// Sync state, same three columns and same reasoning as every other synced table.
  final DateTime? updatedAt;
  final int revision;
  final int? syncedRevision;
  const AppNotificationRow({
    required this.id,
    required this.type,
    required this.occurredAt,
    this.readAt,
    this.medicationId,
    this.reminderId,
    this.pressureDropHpa,
    this.updatedAt,
    required this.revision,
    this.syncedRevision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['type'] = Variable<String>(
        $AppNotificationsTable.$convertertype.toSql(type),
      );
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<DateTime>(readAt);
    }
    if (!nullToAbsent || medicationId != null) {
      map['medication_id'] = Variable<String>(medicationId);
    }
    if (!nullToAbsent || reminderId != null) {
      map['reminder_id'] = Variable<String>(reminderId);
    }
    if (!nullToAbsent || pressureDropHpa != null) {
      map['pressure_drop_hpa'] = Variable<double>(pressureDropHpa);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['revision'] = Variable<int>(revision);
    if (!nullToAbsent || syncedRevision != null) {
      map['synced_revision'] = Variable<int>(syncedRevision);
    }
    return map;
  }

  AppNotificationsCompanion toCompanion(bool nullToAbsent) {
    return AppNotificationsCompanion(
      id: Value(id),
      type: Value(type),
      occurredAt: Value(occurredAt),
      readAt: readAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readAt),
      medicationId: medicationId == null && nullToAbsent
          ? const Value.absent()
          : Value(medicationId),
      reminderId: reminderId == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderId),
      pressureDropHpa: pressureDropHpa == null && nullToAbsent
          ? const Value.absent()
          : Value(pressureDropHpa),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      revision: Value(revision),
      syncedRevision: syncedRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedRevision),
    );
  }

  factory AppNotificationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppNotificationRow(
      id: serializer.fromJson<String>(json['id']),
      type: $AppNotificationsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
      medicationId: serializer.fromJson<String?>(json['medicationId']),
      reminderId: serializer.fromJson<String?>(json['reminderId']),
      pressureDropHpa: serializer.fromJson<double?>(json['pressureDropHpa']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      revision: serializer.fromJson<int>(json['revision']),
      syncedRevision: serializer.fromJson<int?>(json['syncedRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(
        $AppNotificationsTable.$convertertype.toJson(type),
      ),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'readAt': serializer.toJson<DateTime?>(readAt),
      'medicationId': serializer.toJson<String?>(medicationId),
      'reminderId': serializer.toJson<String?>(reminderId),
      'pressureDropHpa': serializer.toJson<double?>(pressureDropHpa),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'revision': serializer.toJson<int>(revision),
      'syncedRevision': serializer.toJson<int?>(syncedRevision),
    };
  }

  AppNotificationRow copyWith({
    String? id,
    NotificationType? type,
    DateTime? occurredAt,
    Value<DateTime?> readAt = const Value.absent(),
    Value<String?> medicationId = const Value.absent(),
    Value<String?> reminderId = const Value.absent(),
    Value<double?> pressureDropHpa = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
    int? revision,
    Value<int?> syncedRevision = const Value.absent(),
  }) => AppNotificationRow(
    id: id ?? this.id,
    type: type ?? this.type,
    occurredAt: occurredAt ?? this.occurredAt,
    readAt: readAt.present ? readAt.value : this.readAt,
    medicationId: medicationId.present ? medicationId.value : this.medicationId,
    reminderId: reminderId.present ? reminderId.value : this.reminderId,
    pressureDropHpa: pressureDropHpa.present
        ? pressureDropHpa.value
        : this.pressureDropHpa,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    revision: revision ?? this.revision,
    syncedRevision: syncedRevision.present
        ? syncedRevision.value
        : this.syncedRevision,
  );
  AppNotificationRow copyWithCompanion(AppNotificationsCompanion data) {
    return AppNotificationRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      reminderId: data.reminderId.present
          ? data.reminderId.value
          : this.reminderId,
      pressureDropHpa: data.pressureDropHpa.present
          ? data.pressureDropHpa.value
          : this.pressureDropHpa,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      revision: data.revision.present ? data.revision.value : this.revision,
      syncedRevision: data.syncedRevision.present
          ? data.syncedRevision.value
          : this.syncedRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppNotificationRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('readAt: $readAt, ')
          ..write('medicationId: $medicationId, ')
          ..write('reminderId: $reminderId, ')
          ..write('pressureDropHpa: $pressureDropHpa, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('syncedRevision: $syncedRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    occurredAt,
    readAt,
    medicationId,
    reminderId,
    pressureDropHpa,
    updatedAt,
    revision,
    syncedRevision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppNotificationRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.occurredAt == this.occurredAt &&
          other.readAt == this.readAt &&
          other.medicationId == this.medicationId &&
          other.reminderId == this.reminderId &&
          other.pressureDropHpa == this.pressureDropHpa &&
          other.updatedAt == this.updatedAt &&
          other.revision == this.revision &&
          other.syncedRevision == this.syncedRevision);
}

class AppNotificationsCompanion extends UpdateCompanion<AppNotificationRow> {
  final Value<String> id;
  final Value<NotificationType> type;
  final Value<DateTime> occurredAt;
  final Value<DateTime?> readAt;
  final Value<String?> medicationId;
  final Value<String?> reminderId;
  final Value<double?> pressureDropHpa;
  final Value<DateTime?> updatedAt;
  final Value<int> revision;
  final Value<int?> syncedRevision;
  final Value<int> rowid;
  const AppNotificationsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.reminderId = const Value.absent(),
    this.pressureDropHpa = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.syncedRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppNotificationsCompanion.insert({
    required String id,
    required NotificationType type,
    required DateTime occurredAt,
    this.readAt = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.reminderId = const Value.absent(),
    this.pressureDropHpa = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.revision = const Value.absent(),
    this.syncedRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       occurredAt = Value(occurredAt);
  static Insertable<AppNotificationRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? readAt,
    Expression<String>? medicationId,
    Expression<String>? reminderId,
    Expression<double>? pressureDropHpa,
    Expression<DateTime>? updatedAt,
    Expression<int>? revision,
    Expression<int>? syncedRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (readAt != null) 'read_at': readAt,
      if (medicationId != null) 'medication_id': medicationId,
      if (reminderId != null) 'reminder_id': reminderId,
      if (pressureDropHpa != null) 'pressure_drop_hpa': pressureDropHpa,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (revision != null) 'revision': revision,
      if (syncedRevision != null) 'synced_revision': syncedRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppNotificationsCompanion copyWith({
    Value<String>? id,
    Value<NotificationType>? type,
    Value<DateTime>? occurredAt,
    Value<DateTime?>? readAt,
    Value<String?>? medicationId,
    Value<String?>? reminderId,
    Value<double?>? pressureDropHpa,
    Value<DateTime?>? updatedAt,
    Value<int>? revision,
    Value<int?>? syncedRevision,
    Value<int>? rowid,
  }) {
    return AppNotificationsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      occurredAt: occurredAt ?? this.occurredAt,
      readAt: readAt ?? this.readAt,
      medicationId: medicationId ?? this.medicationId,
      reminderId: reminderId ?? this.reminderId,
      pressureDropHpa: pressureDropHpa ?? this.pressureDropHpa,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
      syncedRevision: syncedRevision ?? this.syncedRevision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $AppNotificationsTable.$convertertype.toSql(type.value),
      );
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (reminderId.present) {
      map['reminder_id'] = Variable<String>(reminderId.value);
    }
    if (pressureDropHpa.present) {
      map['pressure_drop_hpa'] = Variable<double>(pressureDropHpa.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (syncedRevision.present) {
      map['synced_revision'] = Variable<int>(syncedRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('readAt: $readAt, ')
          ..write('medicationId: $medicationId, ')
          ..write('reminderId: $reminderId, ')
          ..write('pressureDropHpa: $pressureDropHpa, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('revision: $revision, ')
          ..write('syncedRevision: $syncedRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExportRecordsTable extends ExportRecords
    with TableInfo<$ExportRecordsTable, ExportRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExportRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filenameMeta = const VerificationMeta(
    'filename',
  );
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
    'filename',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    filename,
    filePath,
    sizeBytes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'export_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExportRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('filename')) {
      context.handle(
        _filenameMeta,
        filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta),
      );
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExportRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExportRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      filename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filename'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ExportRecordsTable createAlias(String alias) {
    return $ExportRecordsTable(attachedDatabase, alias);
  }
}

class ExportRecordRow extends DataClass implements Insertable<ExportRecordRow> {
  final String id;

  /// `ExportKind.name` — json, csv or pdf.
  final String kind;
  final String filename;

  /// Absolute path in the app's documents directory. Stored rather than rebuilt so a rename of the naming scheme can't orphan old rows.
  final String filePath;
  final int sizeBytes;
  final DateTime createdAt;
  const ExportRecordRow({
    required this.id,
    required this.kind,
    required this.filename,
    required this.filePath,
    required this.sizeBytes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['filename'] = Variable<String>(filename);
    map['file_path'] = Variable<String>(filePath);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExportRecordsCompanion toCompanion(bool nullToAbsent) {
    return ExportRecordsCompanion(
      id: Value(id),
      kind: Value(kind),
      filename: Value(filename),
      filePath: Value(filePath),
      sizeBytes: Value(sizeBytes),
      createdAt: Value(createdAt),
    );
  }

  factory ExportRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExportRecordRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      filename: serializer.fromJson<String>(json['filename']),
      filePath: serializer.fromJson<String>(json['filePath']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'filename': serializer.toJson<String>(filename),
      'filePath': serializer.toJson<String>(filePath),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExportRecordRow copyWith({
    String? id,
    String? kind,
    String? filename,
    String? filePath,
    int? sizeBytes,
    DateTime? createdAt,
  }) => ExportRecordRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    filename: filename ?? this.filename,
    filePath: filePath ?? this.filePath,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    createdAt: createdAt ?? this.createdAt,
  );
  ExportRecordRow copyWithCompanion(ExportRecordsCompanion data) {
    return ExportRecordRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      filename: data.filename.present ? data.filename.value : this.filename,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExportRecordRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('filename: $filename, ')
          ..write('filePath: $filePath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, kind, filename, filePath, sizeBytes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExportRecordRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.filename == this.filename &&
          other.filePath == this.filePath &&
          other.sizeBytes == this.sizeBytes &&
          other.createdAt == this.createdAt);
}

class ExportRecordsCompanion extends UpdateCompanion<ExportRecordRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> filename;
  final Value<String> filePath;
  final Value<int> sizeBytes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ExportRecordsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.filename = const Value.absent(),
    this.filePath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExportRecordsCompanion.insert({
    required String id,
    required String kind,
    required String filename,
    required String filePath,
    required int sizeBytes,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       filename = Value(filename),
       filePath = Value(filePath),
       sizeBytes = Value(sizeBytes),
       createdAt = Value(createdAt);
  static Insertable<ExportRecordRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? filename,
    Expression<String>? filePath,
    Expression<int>? sizeBytes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (filename != null) 'filename': filename,
      if (filePath != null) 'file_path': filePath,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExportRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? filename,
    Value<String>? filePath,
    Value<int>? sizeBytes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ExportRecordsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      filename: filename ?? this.filename,
      filePath: filePath ?? this.filePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExportRecordsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('filename: $filename, ')
          ..write('filePath: $filePath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncTombstonesTable extends SyncTombstones
    with TableInfo<$SyncTombstonesTable, SyncTombstoneRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncTombstonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionMeta = const VerificationMeta(
    'collection',
  );
  @override
  late final GeneratedColumn<String> collection = GeneratedColumn<String>(
    'collection',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [collection, id, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_tombstones';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncTombstoneRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection')) {
      context.handle(
        _collectionMeta,
        collection.isAcceptableOrUnknown(data['collection']!, _collectionMeta),
      );
    } else if (isInserting) {
      context.missing(_collectionMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {collection, id};
  @override
  SyncTombstoneRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncTombstoneRow(
      collection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $SyncTombstonesTable createAlias(String alias) {
    return $SyncTombstonesTable(attachedDatabase, alias);
  }
}

class SyncTombstoneRow extends DataClass
    implements Insertable<SyncTombstoneRow> {
  /// Which kind of record this id belonged to. See `SyncCollection`.
  final String collection;
  final String id;

  /// Doubles as the row's `updatedAt` when a deletion races an edit made on another device — latest wins either way.
  final DateTime deletedAt;
  const SyncTombstoneRow({
    required this.collection,
    required this.id,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection'] = Variable<String>(collection);
    map['id'] = Variable<String>(id);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  SyncTombstonesCompanion toCompanion(bool nullToAbsent) {
    return SyncTombstonesCompanion(
      collection: Value(collection),
      id: Value(id),
      deletedAt: Value(deletedAt),
    );
  }

  factory SyncTombstoneRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncTombstoneRow(
      collection: serializer.fromJson<String>(json['collection']),
      id: serializer.fromJson<String>(json['id']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collection': serializer.toJson<String>(collection),
      'id': serializer.toJson<String>(id),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  SyncTombstoneRow copyWith({
    String? collection,
    String? id,
    DateTime? deletedAt,
  }) => SyncTombstoneRow(
    collection: collection ?? this.collection,
    id: id ?? this.id,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  SyncTombstoneRow copyWithCompanion(SyncTombstonesCompanion data) {
    return SyncTombstoneRow(
      collection: data.collection.present
          ? data.collection.value
          : this.collection,
      id: data.id.present ? data.id.value : this.id,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncTombstoneRow(')
          ..write('collection: $collection, ')
          ..write('id: $id, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(collection, id, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncTombstoneRow &&
          other.collection == this.collection &&
          other.id == this.id &&
          other.deletedAt == this.deletedAt);
}

class SyncTombstonesCompanion extends UpdateCompanion<SyncTombstoneRow> {
  final Value<String> collection;
  final Value<String> id;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const SyncTombstonesCompanion({
    this.collection = const Value.absent(),
    this.id = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncTombstonesCompanion.insert({
    required String collection,
    required String id,
    required DateTime deletedAt,
    this.rowid = const Value.absent(),
  }) : collection = Value(collection),
       id = Value(id),
       deletedAt = Value(deletedAt);
  static Insertable<SyncTombstoneRow> custom({
    Expression<String>? collection,
    Expression<String>? id,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collection != null) 'collection': collection,
      if (id != null) 'id': id,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncTombstonesCompanion copyWith({
    Value<String>? collection,
    Value<String>? id,
    Value<DateTime>? deletedAt,
    Value<int>? rowid,
  }) {
    return SyncTombstonesCompanion(
      collection: collection ?? this.collection,
      id: id ?? this.id,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collection.present) {
      map['collection'] = Variable<String>(collection.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncTombstonesCompanion(')
          ..write('collection: $collection, ')
          ..write('id: $id, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyWeatherTable extends DailyWeather
    with TableInfo<$DailyWeatherTable, DailyWeatherRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyWeatherTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    day,
    capturedAt,
    pressureHpa,
    pressureDelta24hHpa,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_weather';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyWeatherRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  DailyWeatherRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyWeatherRow(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
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
    );
  }

  @override
  $DailyWeatherTable createAlias(String alias) {
    return $DailyWeatherTable(attachedDatabase, alias);
  }
}

class DailyWeatherRow extends DataClass implements Insertable<DailyWeatherRow> {
  /// Local midnight of the day this reading belongs to.
  final DateTime day;
  final DateTime capturedAt;
  final double pressureHpa;
  final double pressureDelta24hHpa;
  const DailyWeatherRow({
    required this.day,
    required this.capturedAt,
    required this.pressureHpa,
    required this.pressureDelta24hHpa,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<DateTime>(day);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['pressure_hpa'] = Variable<double>(pressureHpa);
    map['pressure_delta24h_hpa'] = Variable<double>(pressureDelta24hHpa);
    return map;
  }

  DailyWeatherCompanion toCompanion(bool nullToAbsent) {
    return DailyWeatherCompanion(
      day: Value(day),
      capturedAt: Value(capturedAt),
      pressureHpa: Value(pressureHpa),
      pressureDelta24hHpa: Value(pressureDelta24hHpa),
    );
  }

  factory DailyWeatherRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyWeatherRow(
      day: serializer.fromJson<DateTime>(json['day']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      pressureHpa: serializer.fromJson<double>(json['pressureHpa']),
      pressureDelta24hHpa: serializer.fromJson<double>(
        json['pressureDelta24hHpa'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<DateTime>(day),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'pressureHpa': serializer.toJson<double>(pressureHpa),
      'pressureDelta24hHpa': serializer.toJson<double>(pressureDelta24hHpa),
    };
  }

  DailyWeatherRow copyWith({
    DateTime? day,
    DateTime? capturedAt,
    double? pressureHpa,
    double? pressureDelta24hHpa,
  }) => DailyWeatherRow(
    day: day ?? this.day,
    capturedAt: capturedAt ?? this.capturedAt,
    pressureHpa: pressureHpa ?? this.pressureHpa,
    pressureDelta24hHpa: pressureDelta24hHpa ?? this.pressureDelta24hHpa,
  );
  DailyWeatherRow copyWithCompanion(DailyWeatherCompanion data) {
    return DailyWeatherRow(
      day: data.day.present ? data.day.value : this.day,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      pressureHpa: data.pressureHpa.present
          ? data.pressureHpa.value
          : this.pressureHpa,
      pressureDelta24hHpa: data.pressureDelta24hHpa.present
          ? data.pressureDelta24hHpa.value
          : this.pressureDelta24hHpa,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyWeatherRow(')
          ..write('day: $day, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('pressureHpa: $pressureHpa, ')
          ..write('pressureDelta24hHpa: $pressureDelta24hHpa')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(day, capturedAt, pressureHpa, pressureDelta24hHpa);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyWeatherRow &&
          other.day == this.day &&
          other.capturedAt == this.capturedAt &&
          other.pressureHpa == this.pressureHpa &&
          other.pressureDelta24hHpa == this.pressureDelta24hHpa);
}

class DailyWeatherCompanion extends UpdateCompanion<DailyWeatherRow> {
  final Value<DateTime> day;
  final Value<DateTime> capturedAt;
  final Value<double> pressureHpa;
  final Value<double> pressureDelta24hHpa;
  final Value<int> rowid;
  const DailyWeatherCompanion({
    this.day = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.pressureHpa = const Value.absent(),
    this.pressureDelta24hHpa = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyWeatherCompanion.insert({
    required DateTime day,
    required DateTime capturedAt,
    required double pressureHpa,
    required double pressureDelta24hHpa,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       capturedAt = Value(capturedAt),
       pressureHpa = Value(pressureHpa),
       pressureDelta24hHpa = Value(pressureDelta24hHpa);
  static Insertable<DailyWeatherRow> custom({
    Expression<DateTime>? day,
    Expression<DateTime>? capturedAt,
    Expression<double>? pressureHpa,
    Expression<double>? pressureDelta24hHpa,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (pressureHpa != null) 'pressure_hpa': pressureHpa,
      if (pressureDelta24hHpa != null)
        'pressure_delta24h_hpa': pressureDelta24hHpa,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyWeatherCompanion copyWith({
    Value<DateTime>? day,
    Value<DateTime>? capturedAt,
    Value<double>? pressureHpa,
    Value<double>? pressureDelta24hHpa,
    Value<int>? rowid,
  }) {
    return DailyWeatherCompanion(
      day: day ?? this.day,
      capturedAt: capturedAt ?? this.capturedAt,
      pressureHpa: pressureHpa ?? this.pressureHpa,
      pressureDelta24hHpa: pressureDelta24hHpa ?? this.pressureDelta24hHpa,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyWeatherCompanion(')
          ..write('day: $day, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('pressureHpa: $pressureHpa, ')
          ..write('pressureDelta24hHpa: $pressureDelta24hHpa, ')
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
  late final $AppNotificationsTable appNotifications = $AppNotificationsTable(
    this,
  );
  late final $ExportRecordsTable exportRecords = $ExportRecordsTable(this);
  late final $SyncTombstonesTable syncTombstones = $SyncTombstonesTable(this);
  late final $DailyWeatherTable dailyWeather = $DailyWeatherTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    attacks,
    weatherSnapshots,
    medications,
    medicationReminders,
    appNotifications,
    exportRecords,
    syncTombstones,
    dailyWeather,
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
      Value<List<HeadRegion>> regions,
      Value<String?> medicationName,
      Value<List<String>> symptoms,
      Value<List<String>> triggers,
      Value<String?> notes,
      Value<ExertionLevel?> exertionLevel,
      Value<MedicationEffect?> medicationEffect,
      Value<List<AuraType>?> aura,
      Value<DateTime?> endedAt,
      Value<int?> steps,
      Value<DateTime?> updatedAt,
      Value<int> revision,
      Value<int?> syncedRevision,
      Value<int> rowid,
    });
typedef $$AttacksTableUpdateCompanionBuilder =
    AttacksCompanion Function({
      Value<String> id,
      Value<DateTime> startedAt,
      Value<int> intensity,
      Value<List<HeadRegion>> regions,
      Value<String?> medicationName,
      Value<List<String>> symptoms,
      Value<List<String>> triggers,
      Value<String?> notes,
      Value<ExertionLevel?> exertionLevel,
      Value<MedicationEffect?> medicationEffect,
      Value<List<AuraType>?> aura,
      Value<DateTime?> endedAt,
      Value<int?> steps,
      Value<DateTime?> updatedAt,
      Value<int> revision,
      Value<int?> syncedRevision,
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

  ColumnWithTypeConverterFilters<List<HeadRegion>, List<HeadRegion>, String>
  get regions => $composableBuilder(
    column: $table.regions,
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

  ColumnWithTypeConverterFilters<ExertionLevel?, ExertionLevel, String>
  get exertionLevel => $composableBuilder(
    column: $table.exertionLevel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<MedicationEffect?, MedicationEffect, String>
  get medicationEffect => $composableBuilder(
    column: $table.medicationEffect,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<AuraType>?, List<AuraType>, String>
  get aura => $composableBuilder(
    column: $table.aura,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedRevision => $composableBuilder(
    column: $table.syncedRevision,
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

  ColumnOrderings<String> get regions => $composableBuilder(
    column: $table.regions,
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

  ColumnOrderings<String> get exertionLevel => $composableBuilder(
    column: $table.exertionLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationEffect => $composableBuilder(
    column: $table.medicationEffect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aura => $composableBuilder(
    column: $table.aura,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedRevision => $composableBuilder(
    column: $table.syncedRevision,
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

  GeneratedColumnWithTypeConverter<List<HeadRegion>, String> get regions =>
      $composableBuilder(column: $table.regions, builder: (column) => column);

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

  GeneratedColumnWithTypeConverter<ExertionLevel?, String> get exertionLevel =>
      $composableBuilder(
        column: $table.exertionLevel,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<MedicationEffect?, String>
  get medicationEffect => $composableBuilder(
    column: $table.medicationEffect,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<AuraType>?, String> get aura =>
      $composableBuilder(column: $table.aura, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get syncedRevision => $composableBuilder(
    column: $table.syncedRevision,
    builder: (column) => column,
  );

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
                Value<List<HeadRegion>> regions = const Value.absent(),
                Value<String?> medicationName = const Value.absent(),
                Value<List<String>> symptoms = const Value.absent(),
                Value<List<String>> triggers = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<ExertionLevel?> exertionLevel = const Value.absent(),
                Value<MedicationEffect?> medicationEffect =
                    const Value.absent(),
                Value<List<AuraType>?> aura = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int?> steps = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int?> syncedRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttacksCompanion(
                id: id,
                startedAt: startedAt,
                intensity: intensity,
                regions: regions,
                medicationName: medicationName,
                symptoms: symptoms,
                triggers: triggers,
                notes: notes,
                exertionLevel: exertionLevel,
                medicationEffect: medicationEffect,
                aura: aura,
                endedAt: endedAt,
                steps: steps,
                updatedAt: updatedAt,
                revision: revision,
                syncedRevision: syncedRevision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime startedAt,
                required int intensity,
                Value<List<HeadRegion>> regions = const Value.absent(),
                Value<String?> medicationName = const Value.absent(),
                Value<List<String>> symptoms = const Value.absent(),
                Value<List<String>> triggers = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<ExertionLevel?> exertionLevel = const Value.absent(),
                Value<MedicationEffect?> medicationEffect =
                    const Value.absent(),
                Value<List<AuraType>?> aura = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int?> steps = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int?> syncedRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttacksCompanion.insert(
                id: id,
                startedAt: startedAt,
                intensity: intensity,
                regions: regions,
                medicationName: medicationName,
                symptoms: symptoms,
                triggers: triggers,
                notes: notes,
                exertionLevel: exertionLevel,
                medicationEffect: medicationEffect,
                aura: aura,
                endedAt: endedAt,
                steps: steps,
                updatedAt: updatedAt,
                revision: revision,
                syncedRevision: syncedRevision,
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
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> revision,
      Value<int?> syncedRevision,
      Value<int> rowid,
    });
typedef $$MedicationsTableUpdateCompanionBuilder =
    MedicationsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> revision,
      Value<int?> syncedRevision,
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedRevision => $composableBuilder(
    column: $table.syncedRevision,
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedRevision => $composableBuilder(
    column: $table.syncedRevision,
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get syncedRevision => $composableBuilder(
    column: $table.syncedRevision,
    builder: (column) => column,
  );

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
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int?> syncedRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                syncedRevision: syncedRevision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int?> syncedRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                syncedRevision: syncedRevision,
                rowid: rowid,
              ),
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
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> revision,
      Value<int?> syncedRevision,
      Value<int> rowid,
    });
typedef $$MedicationRemindersTableUpdateCompanionBuilder =
    MedicationRemindersCompanion Function({
      Value<String> id,
      Value<String> medicationId,
      Value<int> minuteOfDay,
      Value<bool> enabled,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> revision,
      Value<int?> syncedRevision,
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedRevision => $composableBuilder(
    column: $table.syncedRevision,
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedRevision => $composableBuilder(
    column: $table.syncedRevision,
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get syncedRevision => $composableBuilder(
    column: $table.syncedRevision,
    builder: (column) => column,
  );

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
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int?> syncedRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationRemindersCompanion(
                id: id,
                medicationId: medicationId,
                minuteOfDay: minuteOfDay,
                enabled: enabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                syncedRevision: syncedRevision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String medicationId,
                required int minuteOfDay,
                Value<bool> enabled = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int?> syncedRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationRemindersCompanion.insert(
                id: id,
                medicationId: medicationId,
                minuteOfDay: minuteOfDay,
                enabled: enabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                revision: revision,
                syncedRevision: syncedRevision,
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
typedef $$AppNotificationsTableCreateCompanionBuilder =
    AppNotificationsCompanion Function({
      required String id,
      required NotificationType type,
      required DateTime occurredAt,
      Value<DateTime?> readAt,
      Value<String?> medicationId,
      Value<String?> reminderId,
      Value<double?> pressureDropHpa,
      Value<DateTime?> updatedAt,
      Value<int> revision,
      Value<int?> syncedRevision,
      Value<int> rowid,
    });
typedef $$AppNotificationsTableUpdateCompanionBuilder =
    AppNotificationsCompanion Function({
      Value<String> id,
      Value<NotificationType> type,
      Value<DateTime> occurredAt,
      Value<DateTime?> readAt,
      Value<String?> medicationId,
      Value<String?> reminderId,
      Value<double?> pressureDropHpa,
      Value<DateTime?> updatedAt,
      Value<int> revision,
      Value<int?> syncedRevision,
      Value<int> rowid,
    });

class $$AppNotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<NotificationType, NotificationType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pressureDropHpa => $composableBuilder(
    column: $table.pressureDropHpa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedRevision => $composableBuilder(
    column: $table.syncedRevision,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppNotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pressureDropHpa => $composableBuilder(
    column: $table.pressureDropHpa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedRevision => $composableBuilder(
    column: $table.syncedRevision,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppNotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NotificationType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  GeneratedColumn<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pressureDropHpa => $composableBuilder(
    column: $table.pressureDropHpa,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get syncedRevision => $composableBuilder(
    column: $table.syncedRevision,
    builder: (column) => column,
  );
}

class $$AppNotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppNotificationsTable,
          AppNotificationRow,
          $$AppNotificationsTableFilterComposer,
          $$AppNotificationsTableOrderingComposer,
          $$AppNotificationsTableAnnotationComposer,
          $$AppNotificationsTableCreateCompanionBuilder,
          $$AppNotificationsTableUpdateCompanionBuilder,
          (
            AppNotificationRow,
            BaseReferences<
              _$AppDatabase,
              $AppNotificationsTable,
              AppNotificationRow
            >,
          ),
          AppNotificationRow,
          PrefetchHooks Function()
        > {
  $$AppNotificationsTableTableManager(
    _$AppDatabase db,
    $AppNotificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppNotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppNotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppNotificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<NotificationType> type = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
                Value<String?> medicationId = const Value.absent(),
                Value<String?> reminderId = const Value.absent(),
                Value<double?> pressureDropHpa = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int?> syncedRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppNotificationsCompanion(
                id: id,
                type: type,
                occurredAt: occurredAt,
                readAt: readAt,
                medicationId: medicationId,
                reminderId: reminderId,
                pressureDropHpa: pressureDropHpa,
                updatedAt: updatedAt,
                revision: revision,
                syncedRevision: syncedRevision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required NotificationType type,
                required DateTime occurredAt,
                Value<DateTime?> readAt = const Value.absent(),
                Value<String?> medicationId = const Value.absent(),
                Value<String?> reminderId = const Value.absent(),
                Value<double?> pressureDropHpa = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int?> syncedRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppNotificationsCompanion.insert(
                id: id,
                type: type,
                occurredAt: occurredAt,
                readAt: readAt,
                medicationId: medicationId,
                reminderId: reminderId,
                pressureDropHpa: pressureDropHpa,
                updatedAt: updatedAt,
                revision: revision,
                syncedRevision: syncedRevision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppNotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppNotificationsTable,
      AppNotificationRow,
      $$AppNotificationsTableFilterComposer,
      $$AppNotificationsTableOrderingComposer,
      $$AppNotificationsTableAnnotationComposer,
      $$AppNotificationsTableCreateCompanionBuilder,
      $$AppNotificationsTableUpdateCompanionBuilder,
      (
        AppNotificationRow,
        BaseReferences<
          _$AppDatabase,
          $AppNotificationsTable,
          AppNotificationRow
        >,
      ),
      AppNotificationRow,
      PrefetchHooks Function()
    >;
typedef $$ExportRecordsTableCreateCompanionBuilder =
    ExportRecordsCompanion Function({
      required String id,
      required String kind,
      required String filename,
      required String filePath,
      required int sizeBytes,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ExportRecordsTableUpdateCompanionBuilder =
    ExportRecordsCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> filename,
      Value<String> filePath,
      Value<int> sizeBytes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ExportRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ExportRecordsTable> {
  $$ExportRecordsTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExportRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExportRecordsTable> {
  $$ExportRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExportRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExportRecordsTable> {
  $$ExportRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ExportRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExportRecordsTable,
          ExportRecordRow,
          $$ExportRecordsTableFilterComposer,
          $$ExportRecordsTableOrderingComposer,
          $$ExportRecordsTableAnnotationComposer,
          $$ExportRecordsTableCreateCompanionBuilder,
          $$ExportRecordsTableUpdateCompanionBuilder,
          (
            ExportRecordRow,
            BaseReferences<_$AppDatabase, $ExportRecordsTable, ExportRecordRow>,
          ),
          ExportRecordRow,
          PrefetchHooks Function()
        > {
  $$ExportRecordsTableTableManager(_$AppDatabase db, $ExportRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExportRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExportRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExportRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> filename = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExportRecordsCompanion(
                id: id,
                kind: kind,
                filename: filename,
                filePath: filePath,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String filename,
                required String filePath,
                required int sizeBytes,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ExportRecordsCompanion.insert(
                id: id,
                kind: kind,
                filename: filename,
                filePath: filePath,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExportRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExportRecordsTable,
      ExportRecordRow,
      $$ExportRecordsTableFilterComposer,
      $$ExportRecordsTableOrderingComposer,
      $$ExportRecordsTableAnnotationComposer,
      $$ExportRecordsTableCreateCompanionBuilder,
      $$ExportRecordsTableUpdateCompanionBuilder,
      (
        ExportRecordRow,
        BaseReferences<_$AppDatabase, $ExportRecordsTable, ExportRecordRow>,
      ),
      ExportRecordRow,
      PrefetchHooks Function()
    >;
typedef $$SyncTombstonesTableCreateCompanionBuilder =
    SyncTombstonesCompanion Function({
      required String collection,
      required String id,
      required DateTime deletedAt,
      Value<int> rowid,
    });
typedef $$SyncTombstonesTableUpdateCompanionBuilder =
    SyncTombstonesCompanion Function({
      Value<String> collection,
      Value<String> id,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });

class $$SyncTombstonesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncTombstonesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncTombstonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncTombstonesTable> {
  $$SyncTombstonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$SyncTombstonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncTombstonesTable,
          SyncTombstoneRow,
          $$SyncTombstonesTableFilterComposer,
          $$SyncTombstonesTableOrderingComposer,
          $$SyncTombstonesTableAnnotationComposer,
          $$SyncTombstonesTableCreateCompanionBuilder,
          $$SyncTombstonesTableUpdateCompanionBuilder,
          (
            SyncTombstoneRow,
            BaseReferences<
              _$AppDatabase,
              $SyncTombstonesTable,
              SyncTombstoneRow
            >,
          ),
          SyncTombstoneRow,
          PrefetchHooks Function()
        > {
  $$SyncTombstonesTableTableManager(
    _$AppDatabase db,
    $SyncTombstonesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncTombstonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncTombstonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncTombstonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> collection = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncTombstonesCompanion(
                collection: collection,
                id: id,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String collection,
                required String id,
                required DateTime deletedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncTombstonesCompanion.insert(
                collection: collection,
                id: id,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncTombstonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncTombstonesTable,
      SyncTombstoneRow,
      $$SyncTombstonesTableFilterComposer,
      $$SyncTombstonesTableOrderingComposer,
      $$SyncTombstonesTableAnnotationComposer,
      $$SyncTombstonesTableCreateCompanionBuilder,
      $$SyncTombstonesTableUpdateCompanionBuilder,
      (
        SyncTombstoneRow,
        BaseReferences<_$AppDatabase, $SyncTombstonesTable, SyncTombstoneRow>,
      ),
      SyncTombstoneRow,
      PrefetchHooks Function()
    >;
typedef $$DailyWeatherTableCreateCompanionBuilder =
    DailyWeatherCompanion Function({
      required DateTime day,
      required DateTime capturedAt,
      required double pressureHpa,
      required double pressureDelta24hHpa,
      Value<int> rowid,
    });
typedef $$DailyWeatherTableUpdateCompanionBuilder =
    DailyWeatherCompanion Function({
      Value<DateTime> day,
      Value<DateTime> capturedAt,
      Value<double> pressureHpa,
      Value<double> pressureDelta24hHpa,
      Value<int> rowid,
    });

class $$DailyWeatherTableFilterComposer
    extends Composer<_$AppDatabase, $DailyWeatherTable> {
  $$DailyWeatherTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

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
}

class $$DailyWeatherTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyWeatherTable> {
  $$DailyWeatherTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

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
}

class $$DailyWeatherTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyWeatherTable> {
  $$DailyWeatherTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

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
}

class $$DailyWeatherTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyWeatherTable,
          DailyWeatherRow,
          $$DailyWeatherTableFilterComposer,
          $$DailyWeatherTableOrderingComposer,
          $$DailyWeatherTableAnnotationComposer,
          $$DailyWeatherTableCreateCompanionBuilder,
          $$DailyWeatherTableUpdateCompanionBuilder,
          (
            DailyWeatherRow,
            BaseReferences<_$AppDatabase, $DailyWeatherTable, DailyWeatherRow>,
          ),
          DailyWeatherRow,
          PrefetchHooks Function()
        > {
  $$DailyWeatherTableTableManager(_$AppDatabase db, $DailyWeatherTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyWeatherTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyWeatherTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyWeatherTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> day = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<double> pressureHpa = const Value.absent(),
                Value<double> pressureDelta24hHpa = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyWeatherCompanion(
                day: day,
                capturedAt: capturedAt,
                pressureHpa: pressureHpa,
                pressureDelta24hHpa: pressureDelta24hHpa,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime day,
                required DateTime capturedAt,
                required double pressureHpa,
                required double pressureDelta24hHpa,
                Value<int> rowid = const Value.absent(),
              }) => DailyWeatherCompanion.insert(
                day: day,
                capturedAt: capturedAt,
                pressureHpa: pressureHpa,
                pressureDelta24hHpa: pressureDelta24hHpa,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyWeatherTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyWeatherTable,
      DailyWeatherRow,
      $$DailyWeatherTableFilterComposer,
      $$DailyWeatherTableOrderingComposer,
      $$DailyWeatherTableAnnotationComposer,
      $$DailyWeatherTableCreateCompanionBuilder,
      $$DailyWeatherTableUpdateCompanionBuilder,
      (
        DailyWeatherRow,
        BaseReferences<_$AppDatabase, $DailyWeatherTable, DailyWeatherRow>,
      ),
      DailyWeatherRow,
      PrefetchHooks Function()
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
  $$AppNotificationsTableTableManager get appNotifications =>
      $$AppNotificationsTableTableManager(_db, _db.appNotifications);
  $$ExportRecordsTableTableManager get exportRecords =>
      $$ExportRecordsTableTableManager(_db, _db.exportRecords);
  $$SyncTombstonesTableTableManager get syncTombstones =>
      $$SyncTombstonesTableTableManager(_db, _db.syncTombstones);
  $$DailyWeatherTableTableManager get dailyWeather =>
      $$DailyWeatherTableTableManager(_db, _db.dailyWeather);
}
