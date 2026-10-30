// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $RawSamplesTable extends RawSamples
    with TableInfo<$RawSamplesTable, RawSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RawSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _timeMsMeta = const VerificationMeta('timeMs');
  @override
  late final GeneratedColumn<int> timeMs = GeneratedColumn<int>(
    'time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pm1Meta = const VerificationMeta('pm1');
  @override
  late final GeneratedColumn<int> pm1 = GeneratedColumn<int>(
    'pm1',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pm25Meta = const VerificationMeta('pm25');
  @override
  late final GeneratedColumn<int> pm25 = GeneratedColumn<int>(
    'pm25',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pm10Meta = const VerificationMeta('pm10');
  @override
  late final GeneratedColumn<int> pm10 = GeneratedColumn<int>(
    'pm10',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<int> stage = GeneratedColumn<int>(
    'stage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tempMeta = const VerificationMeta('temp');
  @override
  late final GeneratedColumn<double> temp = GeneratedColumn<double>(
    'temp',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _humidityMeta = const VerificationMeta(
    'humidity',
  );
  @override
  late final GeneratedColumn<double> humidity = GeneratedColumn<double>(
    'humidity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vocMeta = const VerificationMeta('voc');
  @override
  late final GeneratedColumn<double> voc = GeneratedColumn<double>(
    'voc',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fanRpmMeta = const VerificationMeta('fanRpm');
  @override
  late final GeneratedColumn<int> fanRpm = GeneratedColumn<int>(
    'fan_rpm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batteryPctMeta = const VerificationMeta(
    'batteryPct',
  );
  @override
  late final GeneratedColumn<int> batteryPct = GeneratedColumn<int>(
    'battery_pct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chargingMeta = const VerificationMeta(
    'charging',
  );
  @override
  late final GeneratedColumn<bool> charging = GeneratedColumn<bool>(
    'charging',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("charging" IN (0, 1))',
    ),
  );
  static const VerificationMeta _batteryVMeta = const VerificationMeta(
    'batteryV',
  );
  @override
  late final GeneratedColumn<double> batteryV = GeneratedColumn<double>(
    'battery_v',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    timeMs,
    pm1,
    pm25,
    pm10,
    stage,
    temp,
    humidity,
    voc,
    fanRpm,
    batteryPct,
    charging,
    batteryV,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'raw_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<RawSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('time_ms')) {
      context.handle(
        _timeMsMeta,
        timeMs.isAcceptableOrUnknown(data['time_ms']!, _timeMsMeta),
      );
    }
    if (data.containsKey('pm1')) {
      context.handle(
        _pm1Meta,
        pm1.isAcceptableOrUnknown(data['pm1']!, _pm1Meta),
      );
    } else if (isInserting) {
      context.missing(_pm1Meta);
    }
    if (data.containsKey('pm25')) {
      context.handle(
        _pm25Meta,
        pm25.isAcceptableOrUnknown(data['pm25']!, _pm25Meta),
      );
    } else if (isInserting) {
      context.missing(_pm25Meta);
    }
    if (data.containsKey('pm10')) {
      context.handle(
        _pm10Meta,
        pm10.isAcceptableOrUnknown(data['pm10']!, _pm10Meta),
      );
    } else if (isInserting) {
      context.missing(_pm10Meta);
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    } else if (isInserting) {
      context.missing(_stageMeta);
    }
    if (data.containsKey('temp')) {
      context.handle(
        _tempMeta,
        temp.isAcceptableOrUnknown(data['temp']!, _tempMeta),
      );
    } else if (isInserting) {
      context.missing(_tempMeta);
    }
    if (data.containsKey('humidity')) {
      context.handle(
        _humidityMeta,
        humidity.isAcceptableOrUnknown(data['humidity']!, _humidityMeta),
      );
    } else if (isInserting) {
      context.missing(_humidityMeta);
    }
    if (data.containsKey('voc')) {
      context.handle(
        _vocMeta,
        voc.isAcceptableOrUnknown(data['voc']!, _vocMeta),
      );
    } else if (isInserting) {
      context.missing(_vocMeta);
    }
    if (data.containsKey('fan_rpm')) {
      context.handle(
        _fanRpmMeta,
        fanRpm.isAcceptableOrUnknown(data['fan_rpm']!, _fanRpmMeta),
      );
    } else if (isInserting) {
      context.missing(_fanRpmMeta);
    }
    if (data.containsKey('battery_pct')) {
      context.handle(
        _batteryPctMeta,
        batteryPct.isAcceptableOrUnknown(data['battery_pct']!, _batteryPctMeta),
      );
    } else if (isInserting) {
      context.missing(_batteryPctMeta);
    }
    if (data.containsKey('charging')) {
      context.handle(
        _chargingMeta,
        charging.isAcceptableOrUnknown(data['charging']!, _chargingMeta),
      );
    } else if (isInserting) {
      context.missing(_chargingMeta);
    }
    if (data.containsKey('battery_v')) {
      context.handle(
        _batteryVMeta,
        batteryV.isAcceptableOrUnknown(data['battery_v']!, _batteryVMeta),
      );
    } else if (isInserting) {
      context.missing(_batteryVMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {timeMs};
  @override
  RawSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RawSample(
      timeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_ms'],
      )!,
      pm1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pm1'],
      )!,
      pm25: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pm25'],
      )!,
      pm10: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pm10'],
      )!,
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage'],
      )!,
      temp: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temp'],
      )!,
      humidity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}humidity'],
      )!,
      voc: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}voc'],
      )!,
      fanRpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fan_rpm'],
      )!,
      batteryPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}battery_pct'],
      )!,
      charging: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}charging'],
      )!,
      batteryV: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}battery_v'],
      )!,
    );
  }

  @override
  $RawSamplesTable createAlias(String alias) {
    return $RawSamplesTable(attachedDatabase, alias);
  }
}

class RawSample extends DataClass implements Insertable<RawSample> {
  final int timeMs;
  final int pm1;
  final int pm25;
  final int pm10;
  final int stage;
  final double temp;
  final double humidity;
  final double voc;
  final int fanRpm;
  final int batteryPct;
  final bool charging;
  final double batteryV;
  const RawSample({
    required this.timeMs,
    required this.pm1,
    required this.pm25,
    required this.pm10,
    required this.stage,
    required this.temp,
    required this.humidity,
    required this.voc,
    required this.fanRpm,
    required this.batteryPct,
    required this.charging,
    required this.batteryV,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['time_ms'] = Variable<int>(timeMs);
    map['pm1'] = Variable<int>(pm1);
    map['pm25'] = Variable<int>(pm25);
    map['pm10'] = Variable<int>(pm10);
    map['stage'] = Variable<int>(stage);
    map['temp'] = Variable<double>(temp);
    map['humidity'] = Variable<double>(humidity);
    map['voc'] = Variable<double>(voc);
    map['fan_rpm'] = Variable<int>(fanRpm);
    map['battery_pct'] = Variable<int>(batteryPct);
    map['charging'] = Variable<bool>(charging);
    map['battery_v'] = Variable<double>(batteryV);
    return map;
  }

  RawSamplesCompanion toCompanion(bool nullToAbsent) {
    return RawSamplesCompanion(
      timeMs: Value(timeMs),
      pm1: Value(pm1),
      pm25: Value(pm25),
      pm10: Value(pm10),
      stage: Value(stage),
      temp: Value(temp),
      humidity: Value(humidity),
      voc: Value(voc),
      fanRpm: Value(fanRpm),
      batteryPct: Value(batteryPct),
      charging: Value(charging),
      batteryV: Value(batteryV),
    );
  }

  factory RawSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RawSample(
      timeMs: serializer.fromJson<int>(json['timeMs']),
      pm1: serializer.fromJson<int>(json['pm1']),
      pm25: serializer.fromJson<int>(json['pm25']),
      pm10: serializer.fromJson<int>(json['pm10']),
      stage: serializer.fromJson<int>(json['stage']),
      temp: serializer.fromJson<double>(json['temp']),
      humidity: serializer.fromJson<double>(json['humidity']),
      voc: serializer.fromJson<double>(json['voc']),
      fanRpm: serializer.fromJson<int>(json['fanRpm']),
      batteryPct: serializer.fromJson<int>(json['batteryPct']),
      charging: serializer.fromJson<bool>(json['charging']),
      batteryV: serializer.fromJson<double>(json['batteryV']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'timeMs': serializer.toJson<int>(timeMs),
      'pm1': serializer.toJson<int>(pm1),
      'pm25': serializer.toJson<int>(pm25),
      'pm10': serializer.toJson<int>(pm10),
      'stage': serializer.toJson<int>(stage),
      'temp': serializer.toJson<double>(temp),
      'humidity': serializer.toJson<double>(humidity),
      'voc': serializer.toJson<double>(voc),
      'fanRpm': serializer.toJson<int>(fanRpm),
      'batteryPct': serializer.toJson<int>(batteryPct),
      'charging': serializer.toJson<bool>(charging),
      'batteryV': serializer.toJson<double>(batteryV),
    };
  }

  RawSample copyWith({
    int? timeMs,
    int? pm1,
    int? pm25,
    int? pm10,
    int? stage,
    double? temp,
    double? humidity,
    double? voc,
    int? fanRpm,
    int? batteryPct,
    bool? charging,
    double? batteryV,
  }) => RawSample(
    timeMs: timeMs ?? this.timeMs,
    pm1: pm1 ?? this.pm1,
    pm25: pm25 ?? this.pm25,
    pm10: pm10 ?? this.pm10,
    stage: stage ?? this.stage,
    temp: temp ?? this.temp,
    humidity: humidity ?? this.humidity,
    voc: voc ?? this.voc,
    fanRpm: fanRpm ?? this.fanRpm,
    batteryPct: batteryPct ?? this.batteryPct,
    charging: charging ?? this.charging,
    batteryV: batteryV ?? this.batteryV,
  );
  RawSample copyWithCompanion(RawSamplesCompanion data) {
    return RawSample(
      timeMs: data.timeMs.present ? data.timeMs.value : this.timeMs,
      pm1: data.pm1.present ? data.pm1.value : this.pm1,
      pm25: data.pm25.present ? data.pm25.value : this.pm25,
      pm10: data.pm10.present ? data.pm10.value : this.pm10,
      stage: data.stage.present ? data.stage.value : this.stage,
      temp: data.temp.present ? data.temp.value : this.temp,
      humidity: data.humidity.present ? data.humidity.value : this.humidity,
      voc: data.voc.present ? data.voc.value : this.voc,
      fanRpm: data.fanRpm.present ? data.fanRpm.value : this.fanRpm,
      batteryPct: data.batteryPct.present
          ? data.batteryPct.value
          : this.batteryPct,
      charging: data.charging.present ? data.charging.value : this.charging,
      batteryV: data.batteryV.present ? data.batteryV.value : this.batteryV,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RawSample(')
          ..write('timeMs: $timeMs, ')
          ..write('pm1: $pm1, ')
          ..write('pm25: $pm25, ')
          ..write('pm10: $pm10, ')
          ..write('stage: $stage, ')
          ..write('temp: $temp, ')
          ..write('humidity: $humidity, ')
          ..write('voc: $voc, ')
          ..write('fanRpm: $fanRpm, ')
          ..write('batteryPct: $batteryPct, ')
          ..write('charging: $charging, ')
          ..write('batteryV: $batteryV')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    timeMs,
    pm1,
    pm25,
    pm10,
    stage,
    temp,
    humidity,
    voc,
    fanRpm,
    batteryPct,
    charging,
    batteryV,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RawSample &&
          other.timeMs == this.timeMs &&
          other.pm1 == this.pm1 &&
          other.pm25 == this.pm25 &&
          other.pm10 == this.pm10 &&
          other.stage == this.stage &&
          other.temp == this.temp &&
          other.humidity == this.humidity &&
          other.voc == this.voc &&
          other.fanRpm == this.fanRpm &&
          other.batteryPct == this.batteryPct &&
          other.charging == this.charging &&
          other.batteryV == this.batteryV);
}

class RawSamplesCompanion extends UpdateCompanion<RawSample> {
  final Value<int> timeMs;
  final Value<int> pm1;
  final Value<int> pm25;
  final Value<int> pm10;
  final Value<int> stage;
  final Value<double> temp;
  final Value<double> humidity;
  final Value<double> voc;
  final Value<int> fanRpm;
  final Value<int> batteryPct;
  final Value<bool> charging;
  final Value<double> batteryV;
  const RawSamplesCompanion({
    this.timeMs = const Value.absent(),
    this.pm1 = const Value.absent(),
    this.pm25 = const Value.absent(),
    this.pm10 = const Value.absent(),
    this.stage = const Value.absent(),
    this.temp = const Value.absent(),
    this.humidity = const Value.absent(),
    this.voc = const Value.absent(),
    this.fanRpm = const Value.absent(),
    this.batteryPct = const Value.absent(),
    this.charging = const Value.absent(),
    this.batteryV = const Value.absent(),
  });
  RawSamplesCompanion.insert({
    this.timeMs = const Value.absent(),
    required int pm1,
    required int pm25,
    required int pm10,
    required int stage,
    required double temp,
    required double humidity,
    required double voc,
    required int fanRpm,
    required int batteryPct,
    required bool charging,
    required double batteryV,
  }) : pm1 = Value(pm1),
       pm25 = Value(pm25),
       pm10 = Value(pm10),
       stage = Value(stage),
       temp = Value(temp),
       humidity = Value(humidity),
       voc = Value(voc),
       fanRpm = Value(fanRpm),
       batteryPct = Value(batteryPct),
       charging = Value(charging),
       batteryV = Value(batteryV);
  static Insertable<RawSample> custom({
    Expression<int>? timeMs,
    Expression<int>? pm1,
    Expression<int>? pm25,
    Expression<int>? pm10,
    Expression<int>? stage,
    Expression<double>? temp,
    Expression<double>? humidity,
    Expression<double>? voc,
    Expression<int>? fanRpm,
    Expression<int>? batteryPct,
    Expression<bool>? charging,
    Expression<double>? batteryV,
  }) {
    return RawValuesInsertable({
      if (timeMs != null) 'time_ms': timeMs,
      if (pm1 != null) 'pm1': pm1,
      if (pm25 != null) 'pm25': pm25,
      if (pm10 != null) 'pm10': pm10,
      if (stage != null) 'stage': stage,
      if (temp != null) 'temp': temp,
      if (humidity != null) 'humidity': humidity,
      if (voc != null) 'voc': voc,
      if (fanRpm != null) 'fan_rpm': fanRpm,
      if (batteryPct != null) 'battery_pct': batteryPct,
      if (charging != null) 'charging': charging,
      if (batteryV != null) 'battery_v': batteryV,
    });
  }

  RawSamplesCompanion copyWith({
    Value<int>? timeMs,
    Value<int>? pm1,
    Value<int>? pm25,
    Value<int>? pm10,
    Value<int>? stage,
    Value<double>? temp,
    Value<double>? humidity,
    Value<double>? voc,
    Value<int>? fanRpm,
    Value<int>? batteryPct,
    Value<bool>? charging,
    Value<double>? batteryV,
  }) {
    return RawSamplesCompanion(
      timeMs: timeMs ?? this.timeMs,
      pm1: pm1 ?? this.pm1,
      pm25: pm25 ?? this.pm25,
      pm10: pm10 ?? this.pm10,
      stage: stage ?? this.stage,
      temp: temp ?? this.temp,
      humidity: humidity ?? this.humidity,
      voc: voc ?? this.voc,
      fanRpm: fanRpm ?? this.fanRpm,
      batteryPct: batteryPct ?? this.batteryPct,
      charging: charging ?? this.charging,
      batteryV: batteryV ?? this.batteryV,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (timeMs.present) {
      map['time_ms'] = Variable<int>(timeMs.value);
    }
    if (pm1.present) {
      map['pm1'] = Variable<int>(pm1.value);
    }
    if (pm25.present) {
      map['pm25'] = Variable<int>(pm25.value);
    }
    if (pm10.present) {
      map['pm10'] = Variable<int>(pm10.value);
    }
    if (stage.present) {
      map['stage'] = Variable<int>(stage.value);
    }
    if (temp.present) {
      map['temp'] = Variable<double>(temp.value);
    }
    if (humidity.present) {
      map['humidity'] = Variable<double>(humidity.value);
    }
    if (voc.present) {
      map['voc'] = Variable<double>(voc.value);
    }
    if (fanRpm.present) {
      map['fan_rpm'] = Variable<int>(fanRpm.value);
    }
    if (batteryPct.present) {
      map['battery_pct'] = Variable<int>(batteryPct.value);
    }
    if (charging.present) {
      map['charging'] = Variable<bool>(charging.value);
    }
    if (batteryV.present) {
      map['battery_v'] = Variable<double>(batteryV.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RawSamplesCompanion(')
          ..write('timeMs: $timeMs, ')
          ..write('pm1: $pm1, ')
          ..write('pm25: $pm25, ')
          ..write('pm10: $pm10, ')
          ..write('stage: $stage, ')
          ..write('temp: $temp, ')
          ..write('humidity: $humidity, ')
          ..write('voc: $voc, ')
          ..write('fanRpm: $fanRpm, ')
          ..write('batteryPct: $batteryPct, ')
          ..write('charging: $charging, ')
          ..write('batteryV: $batteryV')
          ..write(')'))
        .toString();
  }
}

class $MinuteAggregatesTable extends MinuteAggregates
    with TableInfo<$MinuteAggregatesTable, MinuteAggregate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MinuteAggregatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _minuteStartMsMeta = const VerificationMeta(
    'minuteStartMs',
  );
  @override
  late final GeneratedColumn<int> minuteStartMs = GeneratedColumn<int>(
    'minute_start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pm1Meta = const VerificationMeta('pm1');
  @override
  late final GeneratedColumn<double> pm1 = GeneratedColumn<double>(
    'pm1',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pm25Meta = const VerificationMeta('pm25');
  @override
  late final GeneratedColumn<double> pm25 = GeneratedColumn<double>(
    'pm25',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pm10Meta = const VerificationMeta('pm10');
  @override
  late final GeneratedColumn<double> pm10 = GeneratedColumn<double>(
    'pm10',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tempMeta = const VerificationMeta('temp');
  @override
  late final GeneratedColumn<double> temp = GeneratedColumn<double>(
    'temp',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _humidityMeta = const VerificationMeta(
    'humidity',
  );
  @override
  late final GeneratedColumn<double> humidity = GeneratedColumn<double>(
    'humidity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vocMeta = const VerificationMeta('voc');
  @override
  late final GeneratedColumn<double> voc = GeneratedColumn<double>(
    'voc',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fanRpmMeta = const VerificationMeta('fanRpm');
  @override
  late final GeneratedColumn<double> fanRpm = GeneratedColumn<double>(
    'fan_rpm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batteryPctMeta = const VerificationMeta(
    'batteryPct',
  );
  @override
  late final GeneratedColumn<double> batteryPct = GeneratedColumn<double>(
    'battery_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batteryVMeta = const VerificationMeta(
    'batteryV',
  );
  @override
  late final GeneratedColumn<double> batteryV = GeneratedColumn<double>(
    'battery_v',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageMaxMeta = const VerificationMeta(
    'stageMax',
  );
  @override
  late final GeneratedColumn<int> stageMax = GeneratedColumn<int>(
    'stage_max',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stage1CountMeta = const VerificationMeta(
    'stage1Count',
  );
  @override
  late final GeneratedColumn<int> stage1Count = GeneratedColumn<int>(
    'stage1_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stage2CountMeta = const VerificationMeta(
    'stage2Count',
  );
  @override
  late final GeneratedColumn<int> stage2Count = GeneratedColumn<int>(
    'stage2_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stage3CountMeta = const VerificationMeta(
    'stage3Count',
  );
  @override
  late final GeneratedColumn<int> stage3Count = GeneratedColumn<int>(
    'stage3_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stage4CountMeta = const VerificationMeta(
    'stage4Count',
  );
  @override
  late final GeneratedColumn<int> stage4Count = GeneratedColumn<int>(
    'stage4_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stage5CountMeta = const VerificationMeta(
    'stage5Count',
  );
  @override
  late final GeneratedColumn<int> stage5Count = GeneratedColumn<int>(
    'stage5_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sampleCountMeta = const VerificationMeta(
    'sampleCount',
  );
  @override
  late final GeneratedColumn<int> sampleCount = GeneratedColumn<int>(
    'sample_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    minuteStartMs,
    pm1,
    pm25,
    pm10,
    temp,
    humidity,
    voc,
    fanRpm,
    batteryPct,
    batteryV,
    stageMax,
    stage1Count,
    stage2Count,
    stage3Count,
    stage4Count,
    stage5Count,
    sampleCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'minute_aggregates';
  @override
  VerificationContext validateIntegrity(
    Insertable<MinuteAggregate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('minute_start_ms')) {
      context.handle(
        _minuteStartMsMeta,
        minuteStartMs.isAcceptableOrUnknown(
          data['minute_start_ms']!,
          _minuteStartMsMeta,
        ),
      );
    }
    if (data.containsKey('pm1')) {
      context.handle(
        _pm1Meta,
        pm1.isAcceptableOrUnknown(data['pm1']!, _pm1Meta),
      );
    } else if (isInserting) {
      context.missing(_pm1Meta);
    }
    if (data.containsKey('pm25')) {
      context.handle(
        _pm25Meta,
        pm25.isAcceptableOrUnknown(data['pm25']!, _pm25Meta),
      );
    } else if (isInserting) {
      context.missing(_pm25Meta);
    }
    if (data.containsKey('pm10')) {
      context.handle(
        _pm10Meta,
        pm10.isAcceptableOrUnknown(data['pm10']!, _pm10Meta),
      );
    } else if (isInserting) {
      context.missing(_pm10Meta);
    }
    if (data.containsKey('temp')) {
      context.handle(
        _tempMeta,
        temp.isAcceptableOrUnknown(data['temp']!, _tempMeta),
      );
    } else if (isInserting) {
      context.missing(_tempMeta);
    }
    if (data.containsKey('humidity')) {
      context.handle(
        _humidityMeta,
        humidity.isAcceptableOrUnknown(data['humidity']!, _humidityMeta),
      );
    } else if (isInserting) {
      context.missing(_humidityMeta);
    }
    if (data.containsKey('voc')) {
      context.handle(
        _vocMeta,
        voc.isAcceptableOrUnknown(data['voc']!, _vocMeta),
      );
    } else if (isInserting) {
      context.missing(_vocMeta);
    }
    if (data.containsKey('fan_rpm')) {
      context.handle(
        _fanRpmMeta,
        fanRpm.isAcceptableOrUnknown(data['fan_rpm']!, _fanRpmMeta),
      );
    } else if (isInserting) {
      context.missing(_fanRpmMeta);
    }
    if (data.containsKey('battery_pct')) {
      context.handle(
        _batteryPctMeta,
        batteryPct.isAcceptableOrUnknown(data['battery_pct']!, _batteryPctMeta),
      );
    } else if (isInserting) {
      context.missing(_batteryPctMeta);
    }
    if (data.containsKey('battery_v')) {
      context.handle(
        _batteryVMeta,
        batteryV.isAcceptableOrUnknown(data['battery_v']!, _batteryVMeta),
      );
    } else if (isInserting) {
      context.missing(_batteryVMeta);
    }
    if (data.containsKey('stage_max')) {
      context.handle(
        _stageMaxMeta,
        stageMax.isAcceptableOrUnknown(data['stage_max']!, _stageMaxMeta),
      );
    } else if (isInserting) {
      context.missing(_stageMaxMeta);
    }
    if (data.containsKey('stage1_count')) {
      context.handle(
        _stage1CountMeta,
        stage1Count.isAcceptableOrUnknown(
          data['stage1_count']!,
          _stage1CountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stage1CountMeta);
    }
    if (data.containsKey('stage2_count')) {
      context.handle(
        _stage2CountMeta,
        stage2Count.isAcceptableOrUnknown(
          data['stage2_count']!,
          _stage2CountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stage2CountMeta);
    }
    if (data.containsKey('stage3_count')) {
      context.handle(
        _stage3CountMeta,
        stage3Count.isAcceptableOrUnknown(
          data['stage3_count']!,
          _stage3CountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stage3CountMeta);
    }
    if (data.containsKey('stage4_count')) {
      context.handle(
        _stage4CountMeta,
        stage4Count.isAcceptableOrUnknown(
          data['stage4_count']!,
          _stage4CountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stage4CountMeta);
    }
    if (data.containsKey('stage5_count')) {
      context.handle(
        _stage5CountMeta,
        stage5Count.isAcceptableOrUnknown(
          data['stage5_count']!,
          _stage5CountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stage5CountMeta);
    }
    if (data.containsKey('sample_count')) {
      context.handle(
        _sampleCountMeta,
        sampleCount.isAcceptableOrUnknown(
          data['sample_count']!,
          _sampleCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sampleCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {minuteStartMs};
  @override
  MinuteAggregate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MinuteAggregate(
      minuteStartMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute_start_ms'],
      )!,
      pm1: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pm1'],
      )!,
      pm25: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pm25'],
      )!,
      pm10: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pm10'],
      )!,
      temp: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temp'],
      )!,
      humidity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}humidity'],
      )!,
      voc: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}voc'],
      )!,
      fanRpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fan_rpm'],
      )!,
      batteryPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}battery_pct'],
      )!,
      batteryV: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}battery_v'],
      )!,
      stageMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_max'],
      )!,
      stage1Count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage1_count'],
      )!,
      stage2Count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage2_count'],
      )!,
      stage3Count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage3_count'],
      )!,
      stage4Count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage4_count'],
      )!,
      stage5Count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage5_count'],
      )!,
      sampleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_count'],
      )!,
    );
  }

  @override
  $MinuteAggregatesTable createAlias(String alias) {
    return $MinuteAggregatesTable(attachedDatabase, alias);
  }
}

class MinuteAggregate extends DataClass implements Insertable<MinuteAggregate> {
  final int minuteStartMs;
  final double pm1;
  final double pm25;
  final double pm10;
  final double temp;
  final double humidity;
  final double voc;
  final double fanRpm;
  final double batteryPct;
  final double batteryV;
  final int stageMax;
  final int stage1Count;
  final int stage2Count;
  final int stage3Count;
  final int stage4Count;
  final int stage5Count;
  final int sampleCount;
  const MinuteAggregate({
    required this.minuteStartMs,
    required this.pm1,
    required this.pm25,
    required this.pm10,
    required this.temp,
    required this.humidity,
    required this.voc,
    required this.fanRpm,
    required this.batteryPct,
    required this.batteryV,
    required this.stageMax,
    required this.stage1Count,
    required this.stage2Count,
    required this.stage3Count,
    required this.stage4Count,
    required this.stage5Count,
    required this.sampleCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['minute_start_ms'] = Variable<int>(minuteStartMs);
    map['pm1'] = Variable<double>(pm1);
    map['pm25'] = Variable<double>(pm25);
    map['pm10'] = Variable<double>(pm10);
    map['temp'] = Variable<double>(temp);
    map['humidity'] = Variable<double>(humidity);
    map['voc'] = Variable<double>(voc);
    map['fan_rpm'] = Variable<double>(fanRpm);
    map['battery_pct'] = Variable<double>(batteryPct);
    map['battery_v'] = Variable<double>(batteryV);
    map['stage_max'] = Variable<int>(stageMax);
    map['stage1_count'] = Variable<int>(stage1Count);
    map['stage2_count'] = Variable<int>(stage2Count);
    map['stage3_count'] = Variable<int>(stage3Count);
    map['stage4_count'] = Variable<int>(stage4Count);
    map['stage5_count'] = Variable<int>(stage5Count);
    map['sample_count'] = Variable<int>(sampleCount);
    return map;
  }

  MinuteAggregatesCompanion toCompanion(bool nullToAbsent) {
    return MinuteAggregatesCompanion(
      minuteStartMs: Value(minuteStartMs),
      pm1: Value(pm1),
      pm25: Value(pm25),
      pm10: Value(pm10),
      temp: Value(temp),
      humidity: Value(humidity),
      voc: Value(voc),
      fanRpm: Value(fanRpm),
      batteryPct: Value(batteryPct),
      batteryV: Value(batteryV),
      stageMax: Value(stageMax),
      stage1Count: Value(stage1Count),
      stage2Count: Value(stage2Count),
      stage3Count: Value(stage3Count),
      stage4Count: Value(stage4Count),
      stage5Count: Value(stage5Count),
      sampleCount: Value(sampleCount),
    );
  }

  factory MinuteAggregate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MinuteAggregate(
      minuteStartMs: serializer.fromJson<int>(json['minuteStartMs']),
      pm1: serializer.fromJson<double>(json['pm1']),
      pm25: serializer.fromJson<double>(json['pm25']),
      pm10: serializer.fromJson<double>(json['pm10']),
      temp: serializer.fromJson<double>(json['temp']),
      humidity: serializer.fromJson<double>(json['humidity']),
      voc: serializer.fromJson<double>(json['voc']),
      fanRpm: serializer.fromJson<double>(json['fanRpm']),
      batteryPct: serializer.fromJson<double>(json['batteryPct']),
      batteryV: serializer.fromJson<double>(json['batteryV']),
      stageMax: serializer.fromJson<int>(json['stageMax']),
      stage1Count: serializer.fromJson<int>(json['stage1Count']),
      stage2Count: serializer.fromJson<int>(json['stage2Count']),
      stage3Count: serializer.fromJson<int>(json['stage3Count']),
      stage4Count: serializer.fromJson<int>(json['stage4Count']),
      stage5Count: serializer.fromJson<int>(json['stage5Count']),
      sampleCount: serializer.fromJson<int>(json['sampleCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'minuteStartMs': serializer.toJson<int>(minuteStartMs),
      'pm1': serializer.toJson<double>(pm1),
      'pm25': serializer.toJson<double>(pm25),
      'pm10': serializer.toJson<double>(pm10),
      'temp': serializer.toJson<double>(temp),
      'humidity': serializer.toJson<double>(humidity),
      'voc': serializer.toJson<double>(voc),
      'fanRpm': serializer.toJson<double>(fanRpm),
      'batteryPct': serializer.toJson<double>(batteryPct),
      'batteryV': serializer.toJson<double>(batteryV),
      'stageMax': serializer.toJson<int>(stageMax),
      'stage1Count': serializer.toJson<int>(stage1Count),
      'stage2Count': serializer.toJson<int>(stage2Count),
      'stage3Count': serializer.toJson<int>(stage3Count),
      'stage4Count': serializer.toJson<int>(stage4Count),
      'stage5Count': serializer.toJson<int>(stage5Count),
      'sampleCount': serializer.toJson<int>(sampleCount),
    };
  }

  MinuteAggregate copyWith({
    int? minuteStartMs,
    double? pm1,
    double? pm25,
    double? pm10,
    double? temp,
    double? humidity,
    double? voc,
    double? fanRpm,
    double? batteryPct,
    double? batteryV,
    int? stageMax,
    int? stage1Count,
    int? stage2Count,
    int? stage3Count,
    int? stage4Count,
    int? stage5Count,
    int? sampleCount,
  }) => MinuteAggregate(
    minuteStartMs: minuteStartMs ?? this.minuteStartMs,
    pm1: pm1 ?? this.pm1,
    pm25: pm25 ?? this.pm25,
    pm10: pm10 ?? this.pm10,
    temp: temp ?? this.temp,
    humidity: humidity ?? this.humidity,
    voc: voc ?? this.voc,
    fanRpm: fanRpm ?? this.fanRpm,
    batteryPct: batteryPct ?? this.batteryPct,
    batteryV: batteryV ?? this.batteryV,
    stageMax: stageMax ?? this.stageMax,
    stage1Count: stage1Count ?? this.stage1Count,
    stage2Count: stage2Count ?? this.stage2Count,
    stage3Count: stage3Count ?? this.stage3Count,
    stage4Count: stage4Count ?? this.stage4Count,
    stage5Count: stage5Count ?? this.stage5Count,
    sampleCount: sampleCount ?? this.sampleCount,
  );
  MinuteAggregate copyWithCompanion(MinuteAggregatesCompanion data) {
    return MinuteAggregate(
      minuteStartMs: data.minuteStartMs.present
          ? data.minuteStartMs.value
          : this.minuteStartMs,
      pm1: data.pm1.present ? data.pm1.value : this.pm1,
      pm25: data.pm25.present ? data.pm25.value : this.pm25,
      pm10: data.pm10.present ? data.pm10.value : this.pm10,
      temp: data.temp.present ? data.temp.value : this.temp,
      humidity: data.humidity.present ? data.humidity.value : this.humidity,
      voc: data.voc.present ? data.voc.value : this.voc,
      fanRpm: data.fanRpm.present ? data.fanRpm.value : this.fanRpm,
      batteryPct: data.batteryPct.present
          ? data.batteryPct.value
          : this.batteryPct,
      batteryV: data.batteryV.present ? data.batteryV.value : this.batteryV,
      stageMax: data.stageMax.present ? data.stageMax.value : this.stageMax,
      stage1Count: data.stage1Count.present
          ? data.stage1Count.value
          : this.stage1Count,
      stage2Count: data.stage2Count.present
          ? data.stage2Count.value
          : this.stage2Count,
      stage3Count: data.stage3Count.present
          ? data.stage3Count.value
          : this.stage3Count,
      stage4Count: data.stage4Count.present
          ? data.stage4Count.value
          : this.stage4Count,
      stage5Count: data.stage5Count.present
          ? data.stage5Count.value
          : this.stage5Count,
      sampleCount: data.sampleCount.present
          ? data.sampleCount.value
          : this.sampleCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MinuteAggregate(')
          ..write('minuteStartMs: $minuteStartMs, ')
          ..write('pm1: $pm1, ')
          ..write('pm25: $pm25, ')
          ..write('pm10: $pm10, ')
          ..write('temp: $temp, ')
          ..write('humidity: $humidity, ')
          ..write('voc: $voc, ')
          ..write('fanRpm: $fanRpm, ')
          ..write('batteryPct: $batteryPct, ')
          ..write('batteryV: $batteryV, ')
          ..write('stageMax: $stageMax, ')
          ..write('stage1Count: $stage1Count, ')
          ..write('stage2Count: $stage2Count, ')
          ..write('stage3Count: $stage3Count, ')
          ..write('stage4Count: $stage4Count, ')
          ..write('stage5Count: $stage5Count, ')
          ..write('sampleCount: $sampleCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    minuteStartMs,
    pm1,
    pm25,
    pm10,
    temp,
    humidity,
    voc,
    fanRpm,
    batteryPct,
    batteryV,
    stageMax,
    stage1Count,
    stage2Count,
    stage3Count,
    stage4Count,
    stage5Count,
    sampleCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MinuteAggregate &&
          other.minuteStartMs == this.minuteStartMs &&
          other.pm1 == this.pm1 &&
          other.pm25 == this.pm25 &&
          other.pm10 == this.pm10 &&
          other.temp == this.temp &&
          other.humidity == this.humidity &&
          other.voc == this.voc &&
          other.fanRpm == this.fanRpm &&
          other.batteryPct == this.batteryPct &&
          other.batteryV == this.batteryV &&
          other.stageMax == this.stageMax &&
          other.stage1Count == this.stage1Count &&
          other.stage2Count == this.stage2Count &&
          other.stage3Count == this.stage3Count &&
          other.stage4Count == this.stage4Count &&
          other.stage5Count == this.stage5Count &&
          other.sampleCount == this.sampleCount);
}

class MinuteAggregatesCompanion extends UpdateCompanion<MinuteAggregate> {
  final Value<int> minuteStartMs;
  final Value<double> pm1;
  final Value<double> pm25;
  final Value<double> pm10;
  final Value<double> temp;
  final Value<double> humidity;
  final Value<double> voc;
  final Value<double> fanRpm;
  final Value<double> batteryPct;
  final Value<double> batteryV;
  final Value<int> stageMax;
  final Value<int> stage1Count;
  final Value<int> stage2Count;
  final Value<int> stage3Count;
  final Value<int> stage4Count;
  final Value<int> stage5Count;
  final Value<int> sampleCount;
  const MinuteAggregatesCompanion({
    this.minuteStartMs = const Value.absent(),
    this.pm1 = const Value.absent(),
    this.pm25 = const Value.absent(),
    this.pm10 = const Value.absent(),
    this.temp = const Value.absent(),
    this.humidity = const Value.absent(),
    this.voc = const Value.absent(),
    this.fanRpm = const Value.absent(),
    this.batteryPct = const Value.absent(),
    this.batteryV = const Value.absent(),
    this.stageMax = const Value.absent(),
    this.stage1Count = const Value.absent(),
    this.stage2Count = const Value.absent(),
    this.stage3Count = const Value.absent(),
    this.stage4Count = const Value.absent(),
    this.stage5Count = const Value.absent(),
    this.sampleCount = const Value.absent(),
  });
  MinuteAggregatesCompanion.insert({
    this.minuteStartMs = const Value.absent(),
    required double pm1,
    required double pm25,
    required double pm10,
    required double temp,
    required double humidity,
    required double voc,
    required double fanRpm,
    required double batteryPct,
    required double batteryV,
    required int stageMax,
    required int stage1Count,
    required int stage2Count,
    required int stage3Count,
    required int stage4Count,
    required int stage5Count,
    required int sampleCount,
  }) : pm1 = Value(pm1),
       pm25 = Value(pm25),
       pm10 = Value(pm10),
       temp = Value(temp),
       humidity = Value(humidity),
       voc = Value(voc),
       fanRpm = Value(fanRpm),
       batteryPct = Value(batteryPct),
       batteryV = Value(batteryV),
       stageMax = Value(stageMax),
       stage1Count = Value(stage1Count),
       stage2Count = Value(stage2Count),
       stage3Count = Value(stage3Count),
       stage4Count = Value(stage4Count),
       stage5Count = Value(stage5Count),
       sampleCount = Value(sampleCount);
  static Insertable<MinuteAggregate> custom({
    Expression<int>? minuteStartMs,
    Expression<double>? pm1,
    Expression<double>? pm25,
    Expression<double>? pm10,
    Expression<double>? temp,
    Expression<double>? humidity,
    Expression<double>? voc,
    Expression<double>? fanRpm,
    Expression<double>? batteryPct,
    Expression<double>? batteryV,
    Expression<int>? stageMax,
    Expression<int>? stage1Count,
    Expression<int>? stage2Count,
    Expression<int>? stage3Count,
    Expression<int>? stage4Count,
    Expression<int>? stage5Count,
    Expression<int>? sampleCount,
  }) {
    return RawValuesInsertable({
      if (minuteStartMs != null) 'minute_start_ms': minuteStartMs,
      if (pm1 != null) 'pm1': pm1,
      if (pm25 != null) 'pm25': pm25,
      if (pm10 != null) 'pm10': pm10,
      if (temp != null) 'temp': temp,
      if (humidity != null) 'humidity': humidity,
      if (voc != null) 'voc': voc,
      if (fanRpm != null) 'fan_rpm': fanRpm,
      if (batteryPct != null) 'battery_pct': batteryPct,
      if (batteryV != null) 'battery_v': batteryV,
      if (stageMax != null) 'stage_max': stageMax,
      if (stage1Count != null) 'stage1_count': stage1Count,
      if (stage2Count != null) 'stage2_count': stage2Count,
      if (stage3Count != null) 'stage3_count': stage3Count,
      if (stage4Count != null) 'stage4_count': stage4Count,
      if (stage5Count != null) 'stage5_count': stage5Count,
      if (sampleCount != null) 'sample_count': sampleCount,
    });
  }

  MinuteAggregatesCompanion copyWith({
    Value<int>? minuteStartMs,
    Value<double>? pm1,
    Value<double>? pm25,
    Value<double>? pm10,
    Value<double>? temp,
    Value<double>? humidity,
    Value<double>? voc,
    Value<double>? fanRpm,
    Value<double>? batteryPct,
    Value<double>? batteryV,
    Value<int>? stageMax,
    Value<int>? stage1Count,
    Value<int>? stage2Count,
    Value<int>? stage3Count,
    Value<int>? stage4Count,
    Value<int>? stage5Count,
    Value<int>? sampleCount,
  }) {
    return MinuteAggregatesCompanion(
      minuteStartMs: minuteStartMs ?? this.minuteStartMs,
      pm1: pm1 ?? this.pm1,
      pm25: pm25 ?? this.pm25,
      pm10: pm10 ?? this.pm10,
      temp: temp ?? this.temp,
      humidity: humidity ?? this.humidity,
      voc: voc ?? this.voc,
      fanRpm: fanRpm ?? this.fanRpm,
      batteryPct: batteryPct ?? this.batteryPct,
      batteryV: batteryV ?? this.batteryV,
      stageMax: stageMax ?? this.stageMax,
      stage1Count: stage1Count ?? this.stage1Count,
      stage2Count: stage2Count ?? this.stage2Count,
      stage3Count: stage3Count ?? this.stage3Count,
      stage4Count: stage4Count ?? this.stage4Count,
      stage5Count: stage5Count ?? this.stage5Count,
      sampleCount: sampleCount ?? this.sampleCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (minuteStartMs.present) {
      map['minute_start_ms'] = Variable<int>(minuteStartMs.value);
    }
    if (pm1.present) {
      map['pm1'] = Variable<double>(pm1.value);
    }
    if (pm25.present) {
      map['pm25'] = Variable<double>(pm25.value);
    }
    if (pm10.present) {
      map['pm10'] = Variable<double>(pm10.value);
    }
    if (temp.present) {
      map['temp'] = Variable<double>(temp.value);
    }
    if (humidity.present) {
      map['humidity'] = Variable<double>(humidity.value);
    }
    if (voc.present) {
      map['voc'] = Variable<double>(voc.value);
    }
    if (fanRpm.present) {
      map['fan_rpm'] = Variable<double>(fanRpm.value);
    }
    if (batteryPct.present) {
      map['battery_pct'] = Variable<double>(batteryPct.value);
    }
    if (batteryV.present) {
      map['battery_v'] = Variable<double>(batteryV.value);
    }
    if (stageMax.present) {
      map['stage_max'] = Variable<int>(stageMax.value);
    }
    if (stage1Count.present) {
      map['stage1_count'] = Variable<int>(stage1Count.value);
    }
    if (stage2Count.present) {
      map['stage2_count'] = Variable<int>(stage2Count.value);
    }
    if (stage3Count.present) {
      map['stage3_count'] = Variable<int>(stage3Count.value);
    }
    if (stage4Count.present) {
      map['stage4_count'] = Variable<int>(stage4Count.value);
    }
    if (stage5Count.present) {
      map['stage5_count'] = Variable<int>(stage5Count.value);
    }
    if (sampleCount.present) {
      map['sample_count'] = Variable<int>(sampleCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MinuteAggregatesCompanion(')
          ..write('minuteStartMs: $minuteStartMs, ')
          ..write('pm1: $pm1, ')
          ..write('pm25: $pm25, ')
          ..write('pm10: $pm10, ')
          ..write('temp: $temp, ')
          ..write('humidity: $humidity, ')
          ..write('voc: $voc, ')
          ..write('fanRpm: $fanRpm, ')
          ..write('batteryPct: $batteryPct, ')
          ..write('batteryV: $batteryV, ')
          ..write('stageMax: $stageMax, ')
          ..write('stage1Count: $stage1Count, ')
          ..write('stage2Count: $stage2Count, ')
          ..write('stage3Count: $stage3Count, ')
          ..write('stage4Count: $stage4Count, ')
          ..write('stage5Count: $stage5Count, ')
          ..write('sampleCount: $sampleCount')
          ..write(')'))
        .toString();
  }
}

class $HourAggregatesTable extends HourAggregates
    with TableInfo<$HourAggregatesTable, HourAggregate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HourAggregatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hourStartMsMeta = const VerificationMeta(
    'hourStartMs',
  );
  @override
  late final GeneratedColumn<int> hourStartMs = GeneratedColumn<int>(
    'hour_start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pm1Meta = const VerificationMeta('pm1');
  @override
  late final GeneratedColumn<double> pm1 = GeneratedColumn<double>(
    'pm1',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pm25Meta = const VerificationMeta('pm25');
  @override
  late final GeneratedColumn<double> pm25 = GeneratedColumn<double>(
    'pm25',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pm10Meta = const VerificationMeta('pm10');
  @override
  late final GeneratedColumn<double> pm10 = GeneratedColumn<double>(
    'pm10',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tempMeta = const VerificationMeta('temp');
  @override
  late final GeneratedColumn<double> temp = GeneratedColumn<double>(
    'temp',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _humidityMeta = const VerificationMeta(
    'humidity',
  );
  @override
  late final GeneratedColumn<double> humidity = GeneratedColumn<double>(
    'humidity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vocMeta = const VerificationMeta('voc');
  @override
  late final GeneratedColumn<double> voc = GeneratedColumn<double>(
    'voc',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fanRpmMeta = const VerificationMeta('fanRpm');
  @override
  late final GeneratedColumn<double> fanRpm = GeneratedColumn<double>(
    'fan_rpm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batteryPctMeta = const VerificationMeta(
    'batteryPct',
  );
  @override
  late final GeneratedColumn<double> batteryPct = GeneratedColumn<double>(
    'battery_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batteryVMeta = const VerificationMeta(
    'batteryV',
  );
  @override
  late final GeneratedColumn<double> batteryV = GeneratedColumn<double>(
    'battery_v',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageMaxMeta = const VerificationMeta(
    'stageMax',
  );
  @override
  late final GeneratedColumn<int> stageMax = GeneratedColumn<int>(
    'stage_max',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stage1CountMeta = const VerificationMeta(
    'stage1Count',
  );
  @override
  late final GeneratedColumn<int> stage1Count = GeneratedColumn<int>(
    'stage1_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stage2CountMeta = const VerificationMeta(
    'stage2Count',
  );
  @override
  late final GeneratedColumn<int> stage2Count = GeneratedColumn<int>(
    'stage2_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stage3CountMeta = const VerificationMeta(
    'stage3Count',
  );
  @override
  late final GeneratedColumn<int> stage3Count = GeneratedColumn<int>(
    'stage3_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stage4CountMeta = const VerificationMeta(
    'stage4Count',
  );
  @override
  late final GeneratedColumn<int> stage4Count = GeneratedColumn<int>(
    'stage4_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stage5CountMeta = const VerificationMeta(
    'stage5Count',
  );
  @override
  late final GeneratedColumn<int> stage5Count = GeneratedColumn<int>(
    'stage5_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sampleCountMeta = const VerificationMeta(
    'sampleCount',
  );
  @override
  late final GeneratedColumn<int> sampleCount = GeneratedColumn<int>(
    'sample_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    hourStartMs,
    pm1,
    pm25,
    pm10,
    temp,
    humidity,
    voc,
    fanRpm,
    batteryPct,
    batteryV,
    stageMax,
    stage1Count,
    stage2Count,
    stage3Count,
    stage4Count,
    stage5Count,
    sampleCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hour_aggregates';
  @override
  VerificationContext validateIntegrity(
    Insertable<HourAggregate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('hour_start_ms')) {
      context.handle(
        _hourStartMsMeta,
        hourStartMs.isAcceptableOrUnknown(
          data['hour_start_ms']!,
          _hourStartMsMeta,
        ),
      );
    }
    if (data.containsKey('pm1')) {
      context.handle(
        _pm1Meta,
        pm1.isAcceptableOrUnknown(data['pm1']!, _pm1Meta),
      );
    } else if (isInserting) {
      context.missing(_pm1Meta);
    }
    if (data.containsKey('pm25')) {
      context.handle(
        _pm25Meta,
        pm25.isAcceptableOrUnknown(data['pm25']!, _pm25Meta),
      );
    } else if (isInserting) {
      context.missing(_pm25Meta);
    }
    if (data.containsKey('pm10')) {
      context.handle(
        _pm10Meta,
        pm10.isAcceptableOrUnknown(data['pm10']!, _pm10Meta),
      );
    } else if (isInserting) {
      context.missing(_pm10Meta);
    }
    if (data.containsKey('temp')) {
      context.handle(
        _tempMeta,
        temp.isAcceptableOrUnknown(data['temp']!, _tempMeta),
      );
    } else if (isInserting) {
      context.missing(_tempMeta);
    }
    if (data.containsKey('humidity')) {
      context.handle(
        _humidityMeta,
        humidity.isAcceptableOrUnknown(data['humidity']!, _humidityMeta),
      );
    } else if (isInserting) {
      context.missing(_humidityMeta);
    }
    if (data.containsKey('voc')) {
      context.handle(
        _vocMeta,
        voc.isAcceptableOrUnknown(data['voc']!, _vocMeta),
      );
    } else if (isInserting) {
      context.missing(_vocMeta);
    }
    if (data.containsKey('fan_rpm')) {
      context.handle(
        _fanRpmMeta,
        fanRpm.isAcceptableOrUnknown(data['fan_rpm']!, _fanRpmMeta),
      );
    } else if (isInserting) {
      context.missing(_fanRpmMeta);
    }
    if (data.containsKey('battery_pct')) {
      context.handle(
        _batteryPctMeta,
        batteryPct.isAcceptableOrUnknown(data['battery_pct']!, _batteryPctMeta),
      );
    } else if (isInserting) {
      context.missing(_batteryPctMeta);
    }
    if (data.containsKey('battery_v')) {
      context.handle(
        _batteryVMeta,
        batteryV.isAcceptableOrUnknown(data['battery_v']!, _batteryVMeta),
      );
    } else if (isInserting) {
      context.missing(_batteryVMeta);
    }
    if (data.containsKey('stage_max')) {
      context.handle(
        _stageMaxMeta,
        stageMax.isAcceptableOrUnknown(data['stage_max']!, _stageMaxMeta),
      );
    } else if (isInserting) {
      context.missing(_stageMaxMeta);
    }
    if (data.containsKey('stage1_count')) {
      context.handle(
        _stage1CountMeta,
        stage1Count.isAcceptableOrUnknown(
          data['stage1_count']!,
          _stage1CountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stage1CountMeta);
    }
    if (data.containsKey('stage2_count')) {
      context.handle(
        _stage2CountMeta,
        stage2Count.isAcceptableOrUnknown(
          data['stage2_count']!,
          _stage2CountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stage2CountMeta);
    }
    if (data.containsKey('stage3_count')) {
      context.handle(
        _stage3CountMeta,
        stage3Count.isAcceptableOrUnknown(
          data['stage3_count']!,
          _stage3CountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stage3CountMeta);
    }
    if (data.containsKey('stage4_count')) {
      context.handle(
        _stage4CountMeta,
        stage4Count.isAcceptableOrUnknown(
          data['stage4_count']!,
          _stage4CountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stage4CountMeta);
    }
    if (data.containsKey('stage5_count')) {
      context.handle(
        _stage5CountMeta,
        stage5Count.isAcceptableOrUnknown(
          data['stage5_count']!,
          _stage5CountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stage5CountMeta);
    }
    if (data.containsKey('sample_count')) {
      context.handle(
        _sampleCountMeta,
        sampleCount.isAcceptableOrUnknown(
          data['sample_count']!,
          _sampleCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sampleCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {hourStartMs};
  @override
  HourAggregate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HourAggregate(
      hourStartMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour_start_ms'],
      )!,
      pm1: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pm1'],
      )!,
      pm25: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pm25'],
      )!,
      pm10: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pm10'],
      )!,
      temp: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temp'],
      )!,
      humidity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}humidity'],
      )!,
      voc: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}voc'],
      )!,
      fanRpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fan_rpm'],
      )!,
      batteryPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}battery_pct'],
      )!,
      batteryV: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}battery_v'],
      )!,
      stageMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage_max'],
      )!,
      stage1Count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage1_count'],
      )!,
      stage2Count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage2_count'],
      )!,
      stage3Count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage3_count'],
      )!,
      stage4Count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage4_count'],
      )!,
      stage5Count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage5_count'],
      )!,
      sampleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_count'],
      )!,
    );
  }

  @override
  $HourAggregatesTable createAlias(String alias) {
    return $HourAggregatesTable(attachedDatabase, alias);
  }
}

class HourAggregate extends DataClass implements Insertable<HourAggregate> {
  final int hourStartMs;
  final double pm1;
  final double pm25;
  final double pm10;
  final double temp;
  final double humidity;
  final double voc;
  final double fanRpm;
  final double batteryPct;
  final double batteryV;
  final int stageMax;
  final int stage1Count;
  final int stage2Count;
  final int stage3Count;
  final int stage4Count;
  final int stage5Count;
  final int sampleCount;
  const HourAggregate({
    required this.hourStartMs,
    required this.pm1,
    required this.pm25,
    required this.pm10,
    required this.temp,
    required this.humidity,
    required this.voc,
    required this.fanRpm,
    required this.batteryPct,
    required this.batteryV,
    required this.stageMax,
    required this.stage1Count,
    required this.stage2Count,
    required this.stage3Count,
    required this.stage4Count,
    required this.stage5Count,
    required this.sampleCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['hour_start_ms'] = Variable<int>(hourStartMs);
    map['pm1'] = Variable<double>(pm1);
    map['pm25'] = Variable<double>(pm25);
    map['pm10'] = Variable<double>(pm10);
    map['temp'] = Variable<double>(temp);
    map['humidity'] = Variable<double>(humidity);
    map['voc'] = Variable<double>(voc);
    map['fan_rpm'] = Variable<double>(fanRpm);
    map['battery_pct'] = Variable<double>(batteryPct);
    map['battery_v'] = Variable<double>(batteryV);
    map['stage_max'] = Variable<int>(stageMax);
    map['stage1_count'] = Variable<int>(stage1Count);
    map['stage2_count'] = Variable<int>(stage2Count);
    map['stage3_count'] = Variable<int>(stage3Count);
    map['stage4_count'] = Variable<int>(stage4Count);
    map['stage5_count'] = Variable<int>(stage5Count);
    map['sample_count'] = Variable<int>(sampleCount);
    return map;
  }

  HourAggregatesCompanion toCompanion(bool nullToAbsent) {
    return HourAggregatesCompanion(
      hourStartMs: Value(hourStartMs),
      pm1: Value(pm1),
      pm25: Value(pm25),
      pm10: Value(pm10),
      temp: Value(temp),
      humidity: Value(humidity),
      voc: Value(voc),
      fanRpm: Value(fanRpm),
      batteryPct: Value(batteryPct),
      batteryV: Value(batteryV),
      stageMax: Value(stageMax),
      stage1Count: Value(stage1Count),
      stage2Count: Value(stage2Count),
      stage3Count: Value(stage3Count),
      stage4Count: Value(stage4Count),
      stage5Count: Value(stage5Count),
      sampleCount: Value(sampleCount),
    );
  }

  factory HourAggregate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HourAggregate(
      hourStartMs: serializer.fromJson<int>(json['hourStartMs']),
      pm1: serializer.fromJson<double>(json['pm1']),
      pm25: serializer.fromJson<double>(json['pm25']),
      pm10: serializer.fromJson<double>(json['pm10']),
      temp: serializer.fromJson<double>(json['temp']),
      humidity: serializer.fromJson<double>(json['humidity']),
      voc: serializer.fromJson<double>(json['voc']),
      fanRpm: serializer.fromJson<double>(json['fanRpm']),
      batteryPct: serializer.fromJson<double>(json['batteryPct']),
      batteryV: serializer.fromJson<double>(json['batteryV']),
      stageMax: serializer.fromJson<int>(json['stageMax']),
      stage1Count: serializer.fromJson<int>(json['stage1Count']),
      stage2Count: serializer.fromJson<int>(json['stage2Count']),
      stage3Count: serializer.fromJson<int>(json['stage3Count']),
      stage4Count: serializer.fromJson<int>(json['stage4Count']),
      stage5Count: serializer.fromJson<int>(json['stage5Count']),
      sampleCount: serializer.fromJson<int>(json['sampleCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hourStartMs': serializer.toJson<int>(hourStartMs),
      'pm1': serializer.toJson<double>(pm1),
      'pm25': serializer.toJson<double>(pm25),
      'pm10': serializer.toJson<double>(pm10),
      'temp': serializer.toJson<double>(temp),
      'humidity': serializer.toJson<double>(humidity),
      'voc': serializer.toJson<double>(voc),
      'fanRpm': serializer.toJson<double>(fanRpm),
      'batteryPct': serializer.toJson<double>(batteryPct),
      'batteryV': serializer.toJson<double>(batteryV),
      'stageMax': serializer.toJson<int>(stageMax),
      'stage1Count': serializer.toJson<int>(stage1Count),
      'stage2Count': serializer.toJson<int>(stage2Count),
      'stage3Count': serializer.toJson<int>(stage3Count),
      'stage4Count': serializer.toJson<int>(stage4Count),
      'stage5Count': serializer.toJson<int>(stage5Count),
      'sampleCount': serializer.toJson<int>(sampleCount),
    };
  }

  HourAggregate copyWith({
    int? hourStartMs,
    double? pm1,
    double? pm25,
    double? pm10,
    double? temp,
    double? humidity,
    double? voc,
    double? fanRpm,
    double? batteryPct,
    double? batteryV,
    int? stageMax,
    int? stage1Count,
    int? stage2Count,
    int? stage3Count,
    int? stage4Count,
    int? stage5Count,
    int? sampleCount,
  }) => HourAggregate(
    hourStartMs: hourStartMs ?? this.hourStartMs,
    pm1: pm1 ?? this.pm1,
    pm25: pm25 ?? this.pm25,
    pm10: pm10 ?? this.pm10,
    temp: temp ?? this.temp,
    humidity: humidity ?? this.humidity,
    voc: voc ?? this.voc,
    fanRpm: fanRpm ?? this.fanRpm,
    batteryPct: batteryPct ?? this.batteryPct,
    batteryV: batteryV ?? this.batteryV,
    stageMax: stageMax ?? this.stageMax,
    stage1Count: stage1Count ?? this.stage1Count,
    stage2Count: stage2Count ?? this.stage2Count,
    stage3Count: stage3Count ?? this.stage3Count,
    stage4Count: stage4Count ?? this.stage4Count,
    stage5Count: stage5Count ?? this.stage5Count,
    sampleCount: sampleCount ?? this.sampleCount,
  );
  HourAggregate copyWithCompanion(HourAggregatesCompanion data) {
    return HourAggregate(
      hourStartMs: data.hourStartMs.present
          ? data.hourStartMs.value
          : this.hourStartMs,
      pm1: data.pm1.present ? data.pm1.value : this.pm1,
      pm25: data.pm25.present ? data.pm25.value : this.pm25,
      pm10: data.pm10.present ? data.pm10.value : this.pm10,
      temp: data.temp.present ? data.temp.value : this.temp,
      humidity: data.humidity.present ? data.humidity.value : this.humidity,
      voc: data.voc.present ? data.voc.value : this.voc,
      fanRpm: data.fanRpm.present ? data.fanRpm.value : this.fanRpm,
      batteryPct: data.batteryPct.present
          ? data.batteryPct.value
          : this.batteryPct,
      batteryV: data.batteryV.present ? data.batteryV.value : this.batteryV,
      stageMax: data.stageMax.present ? data.stageMax.value : this.stageMax,
      stage1Count: data.stage1Count.present
          ? data.stage1Count.value
          : this.stage1Count,
      stage2Count: data.stage2Count.present
          ? data.stage2Count.value
          : this.stage2Count,
      stage3Count: data.stage3Count.present
          ? data.stage3Count.value
          : this.stage3Count,
      stage4Count: data.stage4Count.present
          ? data.stage4Count.value
          : this.stage4Count,
      stage5Count: data.stage5Count.present
          ? data.stage5Count.value
          : this.stage5Count,
      sampleCount: data.sampleCount.present
          ? data.sampleCount.value
          : this.sampleCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HourAggregate(')
          ..write('hourStartMs: $hourStartMs, ')
          ..write('pm1: $pm1, ')
          ..write('pm25: $pm25, ')
          ..write('pm10: $pm10, ')
          ..write('temp: $temp, ')
          ..write('humidity: $humidity, ')
          ..write('voc: $voc, ')
          ..write('fanRpm: $fanRpm, ')
          ..write('batteryPct: $batteryPct, ')
          ..write('batteryV: $batteryV, ')
          ..write('stageMax: $stageMax, ')
          ..write('stage1Count: $stage1Count, ')
          ..write('stage2Count: $stage2Count, ')
          ..write('stage3Count: $stage3Count, ')
          ..write('stage4Count: $stage4Count, ')
          ..write('stage5Count: $stage5Count, ')
          ..write('sampleCount: $sampleCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    hourStartMs,
    pm1,
    pm25,
    pm10,
    temp,
    humidity,
    voc,
    fanRpm,
    batteryPct,
    batteryV,
    stageMax,
    stage1Count,
    stage2Count,
    stage3Count,
    stage4Count,
    stage5Count,
    sampleCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HourAggregate &&
          other.hourStartMs == this.hourStartMs &&
          other.pm1 == this.pm1 &&
          other.pm25 == this.pm25 &&
          other.pm10 == this.pm10 &&
          other.temp == this.temp &&
          other.humidity == this.humidity &&
          other.voc == this.voc &&
          other.fanRpm == this.fanRpm &&
          other.batteryPct == this.batteryPct &&
          other.batteryV == this.batteryV &&
          other.stageMax == this.stageMax &&
          other.stage1Count == this.stage1Count &&
          other.stage2Count == this.stage2Count &&
          other.stage3Count == this.stage3Count &&
          other.stage4Count == this.stage4Count &&
          other.stage5Count == this.stage5Count &&
          other.sampleCount == this.sampleCount);
}

class HourAggregatesCompanion extends UpdateCompanion<HourAggregate> {
  final Value<int> hourStartMs;
  final Value<double> pm1;
  final Value<double> pm25;
  final Value<double> pm10;
  final Value<double> temp;
  final Value<double> humidity;
  final Value<double> voc;
  final Value<double> fanRpm;
  final Value<double> batteryPct;
  final Value<double> batteryV;
  final Value<int> stageMax;
  final Value<int> stage1Count;
  final Value<int> stage2Count;
  final Value<int> stage3Count;
  final Value<int> stage4Count;
  final Value<int> stage5Count;
  final Value<int> sampleCount;
  const HourAggregatesCompanion({
    this.hourStartMs = const Value.absent(),
    this.pm1 = const Value.absent(),
    this.pm25 = const Value.absent(),
    this.pm10 = const Value.absent(),
    this.temp = const Value.absent(),
    this.humidity = const Value.absent(),
    this.voc = const Value.absent(),
    this.fanRpm = const Value.absent(),
    this.batteryPct = const Value.absent(),
    this.batteryV = const Value.absent(),
    this.stageMax = const Value.absent(),
    this.stage1Count = const Value.absent(),
    this.stage2Count = const Value.absent(),
    this.stage3Count = const Value.absent(),
    this.stage4Count = const Value.absent(),
    this.stage5Count = const Value.absent(),
    this.sampleCount = const Value.absent(),
  });
  HourAggregatesCompanion.insert({
    this.hourStartMs = const Value.absent(),
    required double pm1,
    required double pm25,
    required double pm10,
    required double temp,
    required double humidity,
    required double voc,
    required double fanRpm,
    required double batteryPct,
    required double batteryV,
    required int stageMax,
    required int stage1Count,
    required int stage2Count,
    required int stage3Count,
    required int stage4Count,
    required int stage5Count,
    required int sampleCount,
  }) : pm1 = Value(pm1),
       pm25 = Value(pm25),
       pm10 = Value(pm10),
       temp = Value(temp),
       humidity = Value(humidity),
       voc = Value(voc),
       fanRpm = Value(fanRpm),
       batteryPct = Value(batteryPct),
       batteryV = Value(batteryV),
       stageMax = Value(stageMax),
       stage1Count = Value(stage1Count),
       stage2Count = Value(stage2Count),
       stage3Count = Value(stage3Count),
       stage4Count = Value(stage4Count),
       stage5Count = Value(stage5Count),
       sampleCount = Value(sampleCount);
  static Insertable<HourAggregate> custom({
    Expression<int>? hourStartMs,
    Expression<double>? pm1,
    Expression<double>? pm25,
    Expression<double>? pm10,
    Expression<double>? temp,
    Expression<double>? humidity,
    Expression<double>? voc,
    Expression<double>? fanRpm,
    Expression<double>? batteryPct,
    Expression<double>? batteryV,
    Expression<int>? stageMax,
    Expression<int>? stage1Count,
    Expression<int>? stage2Count,
    Expression<int>? stage3Count,
    Expression<int>? stage4Count,
    Expression<int>? stage5Count,
    Expression<int>? sampleCount,
  }) {
    return RawValuesInsertable({
      if (hourStartMs != null) 'hour_start_ms': hourStartMs,
      if (pm1 != null) 'pm1': pm1,
      if (pm25 != null) 'pm25': pm25,
      if (pm10 != null) 'pm10': pm10,
      if (temp != null) 'temp': temp,
      if (humidity != null) 'humidity': humidity,
      if (voc != null) 'voc': voc,
      if (fanRpm != null) 'fan_rpm': fanRpm,
      if (batteryPct != null) 'battery_pct': batteryPct,
      if (batteryV != null) 'battery_v': batteryV,
      if (stageMax != null) 'stage_max': stageMax,
      if (stage1Count != null) 'stage1_count': stage1Count,
      if (stage2Count != null) 'stage2_count': stage2Count,
      if (stage3Count != null) 'stage3_count': stage3Count,
      if (stage4Count != null) 'stage4_count': stage4Count,
      if (stage5Count != null) 'stage5_count': stage5Count,
      if (sampleCount != null) 'sample_count': sampleCount,
    });
  }

  HourAggregatesCompanion copyWith({
    Value<int>? hourStartMs,
    Value<double>? pm1,
    Value<double>? pm25,
    Value<double>? pm10,
    Value<double>? temp,
    Value<double>? humidity,
    Value<double>? voc,
    Value<double>? fanRpm,
    Value<double>? batteryPct,
    Value<double>? batteryV,
    Value<int>? stageMax,
    Value<int>? stage1Count,
    Value<int>? stage2Count,
    Value<int>? stage3Count,
    Value<int>? stage4Count,
    Value<int>? stage5Count,
    Value<int>? sampleCount,
  }) {
    return HourAggregatesCompanion(
      hourStartMs: hourStartMs ?? this.hourStartMs,
      pm1: pm1 ?? this.pm1,
      pm25: pm25 ?? this.pm25,
      pm10: pm10 ?? this.pm10,
      temp: temp ?? this.temp,
      humidity: humidity ?? this.humidity,
      voc: voc ?? this.voc,
      fanRpm: fanRpm ?? this.fanRpm,
      batteryPct: batteryPct ?? this.batteryPct,
      batteryV: batteryV ?? this.batteryV,
      stageMax: stageMax ?? this.stageMax,
      stage1Count: stage1Count ?? this.stage1Count,
      stage2Count: stage2Count ?? this.stage2Count,
      stage3Count: stage3Count ?? this.stage3Count,
      stage4Count: stage4Count ?? this.stage4Count,
      stage5Count: stage5Count ?? this.stage5Count,
      sampleCount: sampleCount ?? this.sampleCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (hourStartMs.present) {
      map['hour_start_ms'] = Variable<int>(hourStartMs.value);
    }
    if (pm1.present) {
      map['pm1'] = Variable<double>(pm1.value);
    }
    if (pm25.present) {
      map['pm25'] = Variable<double>(pm25.value);
    }
    if (pm10.present) {
      map['pm10'] = Variable<double>(pm10.value);
    }
    if (temp.present) {
      map['temp'] = Variable<double>(temp.value);
    }
    if (humidity.present) {
      map['humidity'] = Variable<double>(humidity.value);
    }
    if (voc.present) {
      map['voc'] = Variable<double>(voc.value);
    }
    if (fanRpm.present) {
      map['fan_rpm'] = Variable<double>(fanRpm.value);
    }
    if (batteryPct.present) {
      map['battery_pct'] = Variable<double>(batteryPct.value);
    }
    if (batteryV.present) {
      map['battery_v'] = Variable<double>(batteryV.value);
    }
    if (stageMax.present) {
      map['stage_max'] = Variable<int>(stageMax.value);
    }
    if (stage1Count.present) {
      map['stage1_count'] = Variable<int>(stage1Count.value);
    }
    if (stage2Count.present) {
      map['stage2_count'] = Variable<int>(stage2Count.value);
    }
    if (stage3Count.present) {
      map['stage3_count'] = Variable<int>(stage3Count.value);
    }
    if (stage4Count.present) {
      map['stage4_count'] = Variable<int>(stage4Count.value);
    }
    if (stage5Count.present) {
      map['stage5_count'] = Variable<int>(stage5Count.value);
    }
    if (sampleCount.present) {
      map['sample_count'] = Variable<int>(sampleCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HourAggregatesCompanion(')
          ..write('hourStartMs: $hourStartMs, ')
          ..write('pm1: $pm1, ')
          ..write('pm25: $pm25, ')
          ..write('pm10: $pm10, ')
          ..write('temp: $temp, ')
          ..write('humidity: $humidity, ')
          ..write('voc: $voc, ')
          ..write('fanRpm: $fanRpm, ')
          ..write('batteryPct: $batteryPct, ')
          ..write('batteryV: $batteryV, ')
          ..write('stageMax: $stageMax, ')
          ..write('stage1Count: $stage1Count, ')
          ..write('stage2Count: $stage2Count, ')
          ..write('stage3Count: $stage3Count, ')
          ..write('stage4Count: $stage4Count, ')
          ..write('stage5Count: $stage5Count, ')
          ..write('sampleCount: $sampleCount')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FilterEventsTable extends FilterEvents
    with TableInfo<$FilterEventsTable, FilterEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilterEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timeMsMeta = const VerificationMeta('timeMs');
  @override
  late final GeneratedColumn<int> timeMs = GeneratedColumn<int>(
    'time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, timeMs, kind, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'filter_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilterEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('time_ms')) {
      context.handle(
        _timeMsMeta,
        timeMs.isAcceptableOrUnknown(data['time_ms']!, _timeMsMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMsMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilterEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilterEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_ms'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $FilterEventsTable createAlias(String alias) {
    return $FilterEventsTable(attachedDatabase, alias);
  }
}

class FilterEvent extends DataClass implements Insertable<FilterEvent> {
  final int id;
  final int timeMs;
  final String kind;
  final String note;
  const FilterEvent({
    required this.id,
    required this.timeMs,
    required this.kind,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['time_ms'] = Variable<int>(timeMs);
    map['kind'] = Variable<String>(kind);
    map['note'] = Variable<String>(note);
    return map;
  }

  FilterEventsCompanion toCompanion(bool nullToAbsent) {
    return FilterEventsCompanion(
      id: Value(id),
      timeMs: Value(timeMs),
      kind: Value(kind),
      note: Value(note),
    );
  }

  factory FilterEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilterEvent(
      id: serializer.fromJson<int>(json['id']),
      timeMs: serializer.fromJson<int>(json['timeMs']),
      kind: serializer.fromJson<String>(json['kind']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timeMs': serializer.toJson<int>(timeMs),
      'kind': serializer.toJson<String>(kind),
      'note': serializer.toJson<String>(note),
    };
  }

  FilterEvent copyWith({int? id, int? timeMs, String? kind, String? note}) =>
      FilterEvent(
        id: id ?? this.id,
        timeMs: timeMs ?? this.timeMs,
        kind: kind ?? this.kind,
        note: note ?? this.note,
      );
  FilterEvent copyWithCompanion(FilterEventsCompanion data) {
    return FilterEvent(
      id: data.id.present ? data.id.value : this.id,
      timeMs: data.timeMs.present ? data.timeMs.value : this.timeMs,
      kind: data.kind.present ? data.kind.value : this.kind,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilterEvent(')
          ..write('id: $id, ')
          ..write('timeMs: $timeMs, ')
          ..write('kind: $kind, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timeMs, kind, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilterEvent &&
          other.id == this.id &&
          other.timeMs == this.timeMs &&
          other.kind == this.kind &&
          other.note == this.note);
}

class FilterEventsCompanion extends UpdateCompanion<FilterEvent> {
  final Value<int> id;
  final Value<int> timeMs;
  final Value<String> kind;
  final Value<String> note;
  const FilterEventsCompanion({
    this.id = const Value.absent(),
    this.timeMs = const Value.absent(),
    this.kind = const Value.absent(),
    this.note = const Value.absent(),
  });
  FilterEventsCompanion.insert({
    this.id = const Value.absent(),
    required int timeMs,
    required String kind,
    this.note = const Value.absent(),
  }) : timeMs = Value(timeMs),
       kind = Value(kind);
  static Insertable<FilterEvent> custom({
    Expression<int>? id,
    Expression<int>? timeMs,
    Expression<String>? kind,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timeMs != null) 'time_ms': timeMs,
      if (kind != null) 'kind': kind,
      if (note != null) 'note': note,
    });
  }

  FilterEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? timeMs,
    Value<String>? kind,
    Value<String>? note,
  }) {
    return FilterEventsCompanion(
      id: id ?? this.id,
      timeMs: timeMs ?? this.timeMs,
      kind: kind ?? this.kind,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timeMs.present) {
      map['time_ms'] = Variable<int>(timeMs.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilterEventsCompanion(')
          ..write('id: $id, ')
          ..write('timeMs: $timeMs, ')
          ..write('kind: $kind, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RawSamplesTable rawSamples = $RawSamplesTable(this);
  late final $MinuteAggregatesTable minuteAggregates = $MinuteAggregatesTable(
    this,
  );
  late final $HourAggregatesTable hourAggregates = $HourAggregatesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $FilterEventsTable filterEvents = $FilterEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    rawSamples,
    minuteAggregates,
    hourAggregates,
    appSettings,
    filterEvents,
  ];
}

typedef $$RawSamplesTableCreateCompanionBuilder = RawSamplesCompanion Function({
  Value<int> timeMs,
  required int pm1,
  required int pm25,
  required int pm10,
  required int stage,
  required double temp,
  required double humidity,
  required double voc,
  required int fanRpm,
  required int batteryPct,
  required bool charging,
  required double batteryV,
});
typedef $$RawSamplesTableUpdateCompanionBuilder = RawSamplesCompanion Function({
  Value<int> timeMs,
  Value<int> pm1,
  Value<int> pm25,
  Value<int> pm10,
  Value<int> stage,
  Value<double> temp,
  Value<double> humidity,
  Value<double> voc,
  Value<int> fanRpm,
  Value<int> batteryPct,
  Value<bool> charging,
  Value<double> batteryV,
});

class $$RawSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $RawSamplesTable> {
  $$RawSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pm1 => $composableBuilder(
    column: $table.pm1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pm25 => $composableBuilder(
    column: $table.pm25,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pm10 => $composableBuilder(
    column: $table.pm10,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temp => $composableBuilder(
    column: $table.temp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get humidity => $composableBuilder(
    column: $table.humidity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voc => $composableBuilder(
    column: $table.voc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fanRpm => $composableBuilder(
    column: $table.fanRpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get batteryPct => $composableBuilder(
    column: $table.batteryPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get charging => $composableBuilder(
    column: $table.charging,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get batteryV => $composableBuilder(
    column: $table.batteryV,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RawSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $RawSamplesTable> {
  $$RawSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pm1 => $composableBuilder(
    column: $table.pm1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pm25 => $composableBuilder(
    column: $table.pm25,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pm10 => $composableBuilder(
    column: $table.pm10,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temp => $composableBuilder(
    column: $table.temp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get humidity => $composableBuilder(
    column: $table.humidity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voc => $composableBuilder(
    column: $table.voc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fanRpm => $composableBuilder(
    column: $table.fanRpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get batteryPct => $composableBuilder(
    column: $table.batteryPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get charging => $composableBuilder(
    column: $table.charging,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get batteryV => $composableBuilder(
    column: $table.batteryV,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RawSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RawSamplesTable> {
  $$RawSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get timeMs =>
      $composableBuilder(column: $table.timeMs, builder: (column) => column);

  GeneratedColumn<int> get pm1 =>
      $composableBuilder(column: $table.pm1, builder: (column) => column);

  GeneratedColumn<int> get pm25 =>
      $composableBuilder(column: $table.pm25, builder: (column) => column);

  GeneratedColumn<int> get pm10 =>
      $composableBuilder(column: $table.pm10, builder: (column) => column);

  GeneratedColumn<int> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<double> get temp =>
      $composableBuilder(column: $table.temp, builder: (column) => column);

  GeneratedColumn<double> get humidity =>
      $composableBuilder(column: $table.humidity, builder: (column) => column);

  GeneratedColumn<double> get voc =>
      $composableBuilder(column: $table.voc, builder: (column) => column);

  GeneratedColumn<int> get fanRpm =>
      $composableBuilder(column: $table.fanRpm, builder: (column) => column);

  GeneratedColumn<int> get batteryPct => $composableBuilder(
    column: $table.batteryPct,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get charging =>
      $composableBuilder(column: $table.charging, builder: (column) => column);

  GeneratedColumn<double> get batteryV =>
      $composableBuilder(column: $table.batteryV, builder: (column) => column);
}

class $$RawSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RawSamplesTable,
          RawSample,
          $$RawSamplesTableFilterComposer,
          $$RawSamplesTableOrderingComposer,
          $$RawSamplesTableAnnotationComposer,
          $$RawSamplesTableCreateCompanionBuilder,
          $$RawSamplesTableUpdateCompanionBuilder,
          (
            RawSample,
            BaseReferences<_$AppDatabase, $RawSamplesTable, RawSample>,
          ),
          RawSample,
          PrefetchHooks Function()
        > {
  $$RawSamplesTableTableManager(_$AppDatabase db, $RawSamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RawSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RawSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RawSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> timeMs = const Value.absent(),
                Value<int> pm1 = const Value.absent(),
                Value<int> pm25 = const Value.absent(),
                Value<int> pm10 = const Value.absent(),
                Value<int> stage = const Value.absent(),
                Value<double> temp = const Value.absent(),
                Value<double> humidity = const Value.absent(),
                Value<double> voc = const Value.absent(),
                Value<int> fanRpm = const Value.absent(),
                Value<int> batteryPct = const Value.absent(),
                Value<bool> charging = const Value.absent(),
                Value<double> batteryV = const Value.absent(),
              }) => RawSamplesCompanion(
                timeMs: timeMs,
                pm1: pm1,
                pm25: pm25,
                pm10: pm10,
                stage: stage,
                temp: temp,
                humidity: humidity,
                voc: voc,
                fanRpm: fanRpm,
                batteryPct: batteryPct,
                charging: charging,
                batteryV: batteryV,
              ),
          createCompanionCallback:
              ({
                Value<int> timeMs = const Value.absent(),
                required int pm1,
                required int pm25,
                required int pm10,
                required int stage,
                required double temp,
                required double humidity,
                required double voc,
                required int fanRpm,
                required int batteryPct,
                required bool charging,
                required double batteryV,
              }) => RawSamplesCompanion.insert(
                timeMs: timeMs,
                pm1: pm1,
                pm25: pm25,
                pm10: pm10,
                stage: stage,
                temp: temp,
                humidity: humidity,
                voc: voc,
                fanRpm: fanRpm,
                batteryPct: batteryPct,
                charging: charging,
                batteryV: batteryV,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RawSamplesTable, RawSample>(table),
                  BaseReferences<_$AppDatabase, $RawSamplesTable, RawSample>(
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

typedef $$RawSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RawSamplesTable,
      RawSample,
      $$RawSamplesTableFilterComposer,
      $$RawSamplesTableOrderingComposer,
      $$RawSamplesTableAnnotationComposer,
      $$RawSamplesTableCreateCompanionBuilder,
      $$RawSamplesTableUpdateCompanionBuilder,
      (RawSample, BaseReferences<_$AppDatabase, $RawSamplesTable, RawSample>),
      RawSample,
      PrefetchHooks Function()
    >;
typedef $$MinuteAggregatesTableCreateCompanionBuilder =
    MinuteAggregatesCompanion Function({
      Value<int> minuteStartMs,
      required double pm1,
      required double pm25,
      required double pm10,
      required double temp,
      required double humidity,
      required double voc,
      required double fanRpm,
      required double batteryPct,
      required double batteryV,
      required int stageMax,
      required int stage1Count,
      required int stage2Count,
      required int stage3Count,
      required int stage4Count,
      required int stage5Count,
      required int sampleCount,
    });
typedef $$MinuteAggregatesTableUpdateCompanionBuilder =
    MinuteAggregatesCompanion Function({
      Value<int> minuteStartMs,
      Value<double> pm1,
      Value<double> pm25,
      Value<double> pm10,
      Value<double> temp,
      Value<double> humidity,
      Value<double> voc,
      Value<double> fanRpm,
      Value<double> batteryPct,
      Value<double> batteryV,
      Value<int> stageMax,
      Value<int> stage1Count,
      Value<int> stage2Count,
      Value<int> stage3Count,
      Value<int> stage4Count,
      Value<int> stage5Count,
      Value<int> sampleCount,
    });

class $$MinuteAggregatesTableFilterComposer
    extends Composer<_$AppDatabase, $MinuteAggregatesTable> {
  $$MinuteAggregatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get minuteStartMs => $composableBuilder(
    column: $table.minuteStartMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pm1 => $composableBuilder(
    column: $table.pm1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pm25 => $composableBuilder(
    column: $table.pm25,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pm10 => $composableBuilder(
    column: $table.pm10,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temp => $composableBuilder(
    column: $table.temp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get humidity => $composableBuilder(
    column: $table.humidity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voc => $composableBuilder(
    column: $table.voc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fanRpm => $composableBuilder(
    column: $table.fanRpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get batteryPct => $composableBuilder(
    column: $table.batteryPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get batteryV => $composableBuilder(
    column: $table.batteryV,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stageMax => $composableBuilder(
    column: $table.stageMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage1Count => $composableBuilder(
    column: $table.stage1Count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage2Count => $composableBuilder(
    column: $table.stage2Count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage3Count => $composableBuilder(
    column: $table.stage3Count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage4Count => $composableBuilder(
    column: $table.stage4Count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage5Count => $composableBuilder(
    column: $table.stage5Count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MinuteAggregatesTableOrderingComposer
    extends Composer<_$AppDatabase, $MinuteAggregatesTable> {
  $$MinuteAggregatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get minuteStartMs => $composableBuilder(
    column: $table.minuteStartMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pm1 => $composableBuilder(
    column: $table.pm1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pm25 => $composableBuilder(
    column: $table.pm25,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pm10 => $composableBuilder(
    column: $table.pm10,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temp => $composableBuilder(
    column: $table.temp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get humidity => $composableBuilder(
    column: $table.humidity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voc => $composableBuilder(
    column: $table.voc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fanRpm => $composableBuilder(
    column: $table.fanRpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get batteryPct => $composableBuilder(
    column: $table.batteryPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get batteryV => $composableBuilder(
    column: $table.batteryV,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stageMax => $composableBuilder(
    column: $table.stageMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage1Count => $composableBuilder(
    column: $table.stage1Count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage2Count => $composableBuilder(
    column: $table.stage2Count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage3Count => $composableBuilder(
    column: $table.stage3Count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage4Count => $composableBuilder(
    column: $table.stage4Count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage5Count => $composableBuilder(
    column: $table.stage5Count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MinuteAggregatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MinuteAggregatesTable> {
  $$MinuteAggregatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get minuteStartMs => $composableBuilder(
    column: $table.minuteStartMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pm1 =>
      $composableBuilder(column: $table.pm1, builder: (column) => column);

  GeneratedColumn<double> get pm25 =>
      $composableBuilder(column: $table.pm25, builder: (column) => column);

  GeneratedColumn<double> get pm10 =>
      $composableBuilder(column: $table.pm10, builder: (column) => column);

  GeneratedColumn<double> get temp =>
      $composableBuilder(column: $table.temp, builder: (column) => column);

  GeneratedColumn<double> get humidity =>
      $composableBuilder(column: $table.humidity, builder: (column) => column);

  GeneratedColumn<double> get voc =>
      $composableBuilder(column: $table.voc, builder: (column) => column);

  GeneratedColumn<double> get fanRpm =>
      $composableBuilder(column: $table.fanRpm, builder: (column) => column);

  GeneratedColumn<double> get batteryPct => $composableBuilder(
    column: $table.batteryPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get batteryV =>
      $composableBuilder(column: $table.batteryV, builder: (column) => column);

  GeneratedColumn<int> get stageMax =>
      $composableBuilder(column: $table.stageMax, builder: (column) => column);

  GeneratedColumn<int> get stage1Count => $composableBuilder(
    column: $table.stage1Count,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stage2Count => $composableBuilder(
    column: $table.stage2Count,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stage3Count => $composableBuilder(
    column: $table.stage3Count,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stage4Count => $composableBuilder(
    column: $table.stage4Count,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stage5Count => $composableBuilder(
    column: $table.stage5Count,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => column,
  );
}

class $$MinuteAggregatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MinuteAggregatesTable,
          MinuteAggregate,
          $$MinuteAggregatesTableFilterComposer,
          $$MinuteAggregatesTableOrderingComposer,
          $$MinuteAggregatesTableAnnotationComposer,
          $$MinuteAggregatesTableCreateCompanionBuilder,
          $$MinuteAggregatesTableUpdateCompanionBuilder,
          (
            MinuteAggregate,
            BaseReferences<
              _$AppDatabase,
              $MinuteAggregatesTable,
              MinuteAggregate
            >,
          ),
          MinuteAggregate,
          PrefetchHooks Function()
        > {
  $$MinuteAggregatesTableTableManager(
    _$AppDatabase db,
    $MinuteAggregatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MinuteAggregatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MinuteAggregatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MinuteAggregatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> minuteStartMs = const Value.absent(),
                Value<double> pm1 = const Value.absent(),
                Value<double> pm25 = const Value.absent(),
                Value<double> pm10 = const Value.absent(),
                Value<double> temp = const Value.absent(),
                Value<double> humidity = const Value.absent(),
                Value<double> voc = const Value.absent(),
                Value<double> fanRpm = const Value.absent(),
                Value<double> batteryPct = const Value.absent(),
                Value<double> batteryV = const Value.absent(),
                Value<int> stageMax = const Value.absent(),
                Value<int> stage1Count = const Value.absent(),
                Value<int> stage2Count = const Value.absent(),
                Value<int> stage3Count = const Value.absent(),
                Value<int> stage4Count = const Value.absent(),
                Value<int> stage5Count = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
              }) => MinuteAggregatesCompanion(
                minuteStartMs: minuteStartMs,
                pm1: pm1,
                pm25: pm25,
                pm10: pm10,
                temp: temp,
                humidity: humidity,
                voc: voc,
                fanRpm: fanRpm,
                batteryPct: batteryPct,
                batteryV: batteryV,
                stageMax: stageMax,
                stage1Count: stage1Count,
                stage2Count: stage2Count,
                stage3Count: stage3Count,
                stage4Count: stage4Count,
                stage5Count: stage5Count,
                sampleCount: sampleCount,
              ),
          createCompanionCallback:
              ({
                Value<int> minuteStartMs = const Value.absent(),
                required double pm1,
                required double pm25,
                required double pm10,
                required double temp,
                required double humidity,
                required double voc,
                required double fanRpm,
                required double batteryPct,
                required double batteryV,
                required int stageMax,
                required int stage1Count,
                required int stage2Count,
                required int stage3Count,
                required int stage4Count,
                required int stage5Count,
                required int sampleCount,
              }) => MinuteAggregatesCompanion.insert(
                minuteStartMs: minuteStartMs,
                pm1: pm1,
                pm25: pm25,
                pm10: pm10,
                temp: temp,
                humidity: humidity,
                voc: voc,
                fanRpm: fanRpm,
                batteryPct: batteryPct,
                batteryV: batteryV,
                stageMax: stageMax,
                stage1Count: stage1Count,
                stage2Count: stage2Count,
                stage3Count: stage3Count,
                stage4Count: stage4Count,
                stage5Count: stage5Count,
                sampleCount: sampleCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MinuteAggregatesTable, MinuteAggregate>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MinuteAggregatesTable,
                    MinuteAggregate
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MinuteAggregatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MinuteAggregatesTable,
      MinuteAggregate,
      $$MinuteAggregatesTableFilterComposer,
      $$MinuteAggregatesTableOrderingComposer,
      $$MinuteAggregatesTableAnnotationComposer,
      $$MinuteAggregatesTableCreateCompanionBuilder,
      $$MinuteAggregatesTableUpdateCompanionBuilder,
      (
        MinuteAggregate,
        BaseReferences<_$AppDatabase, $MinuteAggregatesTable, MinuteAggregate>,
      ),
      MinuteAggregate,
      PrefetchHooks Function()
    >;
typedef $$HourAggregatesTableCreateCompanionBuilder =
    HourAggregatesCompanion Function({
      Value<int> hourStartMs,
      required double pm1,
      required double pm25,
      required double pm10,
      required double temp,
      required double humidity,
      required double voc,
      required double fanRpm,
      required double batteryPct,
      required double batteryV,
      required int stageMax,
      required int stage1Count,
      required int stage2Count,
      required int stage3Count,
      required int stage4Count,
      required int stage5Count,
      required int sampleCount,
    });
typedef $$HourAggregatesTableUpdateCompanionBuilder =
    HourAggregatesCompanion Function({
      Value<int> hourStartMs,
      Value<double> pm1,
      Value<double> pm25,
      Value<double> pm10,
      Value<double> temp,
      Value<double> humidity,
      Value<double> voc,
      Value<double> fanRpm,
      Value<double> batteryPct,
      Value<double> batteryV,
      Value<int> stageMax,
      Value<int> stage1Count,
      Value<int> stage2Count,
      Value<int> stage3Count,
      Value<int> stage4Count,
      Value<int> stage5Count,
      Value<int> sampleCount,
    });

class $$HourAggregatesTableFilterComposer
    extends Composer<_$AppDatabase, $HourAggregatesTable> {
  $$HourAggregatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get hourStartMs => $composableBuilder(
    column: $table.hourStartMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pm1 => $composableBuilder(
    column: $table.pm1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pm25 => $composableBuilder(
    column: $table.pm25,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pm10 => $composableBuilder(
    column: $table.pm10,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temp => $composableBuilder(
    column: $table.temp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get humidity => $composableBuilder(
    column: $table.humidity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voc => $composableBuilder(
    column: $table.voc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fanRpm => $composableBuilder(
    column: $table.fanRpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get batteryPct => $composableBuilder(
    column: $table.batteryPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get batteryV => $composableBuilder(
    column: $table.batteryV,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stageMax => $composableBuilder(
    column: $table.stageMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage1Count => $composableBuilder(
    column: $table.stage1Count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage2Count => $composableBuilder(
    column: $table.stage2Count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage3Count => $composableBuilder(
    column: $table.stage3Count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage4Count => $composableBuilder(
    column: $table.stage4Count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage5Count => $composableBuilder(
    column: $table.stage5Count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HourAggregatesTableOrderingComposer
    extends Composer<_$AppDatabase, $HourAggregatesTable> {
  $$HourAggregatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get hourStartMs => $composableBuilder(
    column: $table.hourStartMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pm1 => $composableBuilder(
    column: $table.pm1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pm25 => $composableBuilder(
    column: $table.pm25,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pm10 => $composableBuilder(
    column: $table.pm10,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temp => $composableBuilder(
    column: $table.temp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get humidity => $composableBuilder(
    column: $table.humidity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voc => $composableBuilder(
    column: $table.voc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fanRpm => $composableBuilder(
    column: $table.fanRpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get batteryPct => $composableBuilder(
    column: $table.batteryPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get batteryV => $composableBuilder(
    column: $table.batteryV,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stageMax => $composableBuilder(
    column: $table.stageMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage1Count => $composableBuilder(
    column: $table.stage1Count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage2Count => $composableBuilder(
    column: $table.stage2Count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage3Count => $composableBuilder(
    column: $table.stage3Count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage4Count => $composableBuilder(
    column: $table.stage4Count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage5Count => $composableBuilder(
    column: $table.stage5Count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HourAggregatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HourAggregatesTable> {
  $$HourAggregatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get hourStartMs => $composableBuilder(
    column: $table.hourStartMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pm1 =>
      $composableBuilder(column: $table.pm1, builder: (column) => column);

  GeneratedColumn<double> get pm25 =>
      $composableBuilder(column: $table.pm25, builder: (column) => column);

  GeneratedColumn<double> get pm10 =>
      $composableBuilder(column: $table.pm10, builder: (column) => column);

  GeneratedColumn<double> get temp =>
      $composableBuilder(column: $table.temp, builder: (column) => column);

  GeneratedColumn<double> get humidity =>
      $composableBuilder(column: $table.humidity, builder: (column) => column);

  GeneratedColumn<double> get voc =>
      $composableBuilder(column: $table.voc, builder: (column) => column);

  GeneratedColumn<double> get fanRpm =>
      $composableBuilder(column: $table.fanRpm, builder: (column) => column);

  GeneratedColumn<double> get batteryPct => $composableBuilder(
    column: $table.batteryPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get batteryV =>
      $composableBuilder(column: $table.batteryV, builder: (column) => column);

  GeneratedColumn<int> get stageMax =>
      $composableBuilder(column: $table.stageMax, builder: (column) => column);

  GeneratedColumn<int> get stage1Count => $composableBuilder(
    column: $table.stage1Count,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stage2Count => $composableBuilder(
    column: $table.stage2Count,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stage3Count => $composableBuilder(
    column: $table.stage3Count,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stage4Count => $composableBuilder(
    column: $table.stage4Count,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stage5Count => $composableBuilder(
    column: $table.stage5Count,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => column,
  );
}

class $$HourAggregatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HourAggregatesTable,
          HourAggregate,
          $$HourAggregatesTableFilterComposer,
          $$HourAggregatesTableOrderingComposer,
          $$HourAggregatesTableAnnotationComposer,
          $$HourAggregatesTableCreateCompanionBuilder,
          $$HourAggregatesTableUpdateCompanionBuilder,
          (
            HourAggregate,
            BaseReferences<_$AppDatabase, $HourAggregatesTable, HourAggregate>,
          ),
          HourAggregate,
          PrefetchHooks Function()
        > {
  $$HourAggregatesTableTableManager(
    _$AppDatabase db,
    $HourAggregatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HourAggregatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HourAggregatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HourAggregatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> hourStartMs = const Value.absent(),
                Value<double> pm1 = const Value.absent(),
                Value<double> pm25 = const Value.absent(),
                Value<double> pm10 = const Value.absent(),
                Value<double> temp = const Value.absent(),
                Value<double> humidity = const Value.absent(),
                Value<double> voc = const Value.absent(),
                Value<double> fanRpm = const Value.absent(),
                Value<double> batteryPct = const Value.absent(),
                Value<double> batteryV = const Value.absent(),
                Value<int> stageMax = const Value.absent(),
                Value<int> stage1Count = const Value.absent(),
                Value<int> stage2Count = const Value.absent(),
                Value<int> stage3Count = const Value.absent(),
                Value<int> stage4Count = const Value.absent(),
                Value<int> stage5Count = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
              }) => HourAggregatesCompanion(
                hourStartMs: hourStartMs,
                pm1: pm1,
                pm25: pm25,
                pm10: pm10,
                temp: temp,
                humidity: humidity,
                voc: voc,
                fanRpm: fanRpm,
                batteryPct: batteryPct,
                batteryV: batteryV,
                stageMax: stageMax,
                stage1Count: stage1Count,
                stage2Count: stage2Count,
                stage3Count: stage3Count,
                stage4Count: stage4Count,
                stage5Count: stage5Count,
                sampleCount: sampleCount,
              ),
          createCompanionCallback:
              ({
                Value<int> hourStartMs = const Value.absent(),
                required double pm1,
                required double pm25,
                required double pm10,
                required double temp,
                required double humidity,
                required double voc,
                required double fanRpm,
                required double batteryPct,
                required double batteryV,
                required int stageMax,
                required int stage1Count,
                required int stage2Count,
                required int stage3Count,
                required int stage4Count,
                required int stage5Count,
                required int sampleCount,
              }) => HourAggregatesCompanion.insert(
                hourStartMs: hourStartMs,
                pm1: pm1,
                pm25: pm25,
                pm10: pm10,
                temp: temp,
                humidity: humidity,
                voc: voc,
                fanRpm: fanRpm,
                batteryPct: batteryPct,
                batteryV: batteryV,
                stageMax: stageMax,
                stage1Count: stage1Count,
                stage2Count: stage2Count,
                stage3Count: stage3Count,
                stage4Count: stage4Count,
                stage5Count: stage5Count,
                sampleCount: sampleCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HourAggregatesTable, HourAggregate>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $HourAggregatesTable,
                    HourAggregate
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HourAggregatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HourAggregatesTable,
      HourAggregate,
      $$HourAggregatesTableFilterComposer,
      $$HourAggregatesTableOrderingComposer,
      $$HourAggregatesTableAnnotationComposer,
      $$HourAggregatesTableCreateCompanionBuilder,
      $$HourAggregatesTableUpdateCompanionBuilder,
      (
        HourAggregate,
        BaseReferences<_$AppDatabase, $HourAggregatesTable, HourAggregate>,
      ),
      HourAggregate,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
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

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$FilterEventsTableCreateCompanionBuilder =
    FilterEventsCompanion Function({
      Value<int> id,
      required int timeMs,
      required String kind,
      Value<String> note,
    });
typedef $$FilterEventsTableUpdateCompanionBuilder =
    FilterEventsCompanion Function({
      Value<int> id,
      Value<int> timeMs,
      Value<String> kind,
      Value<String> note,
    });

class $$FilterEventsTableFilterComposer
    extends Composer<_$AppDatabase, $FilterEventsTable> {
  $$FilterEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FilterEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $FilterEventsTable> {
  $$FilterEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FilterEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FilterEventsTable> {
  $$FilterEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timeMs =>
      $composableBuilder(column: $table.timeMs, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$FilterEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FilterEventsTable,
          FilterEvent,
          $$FilterEventsTableFilterComposer,
          $$FilterEventsTableOrderingComposer,
          $$FilterEventsTableAnnotationComposer,
          $$FilterEventsTableCreateCompanionBuilder,
          $$FilterEventsTableUpdateCompanionBuilder,
          (
            FilterEvent,
            BaseReferences<_$AppDatabase, $FilterEventsTable, FilterEvent>,
          ),
          FilterEvent,
          PrefetchHooks Function()
        > {
  $$FilterEventsTableTableManager(_$AppDatabase db, $FilterEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilterEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilterEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilterEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> timeMs = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => FilterEventsCompanion(
                id: id,
                timeMs: timeMs,
                kind: kind,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int timeMs,
                required String kind,
                Value<String> note = const Value.absent(),
              }) => FilterEventsCompanion.insert(
                id: id,
                timeMs: timeMs,
                kind: kind,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FilterEventsTable, FilterEvent>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FilterEventsTable,
                    FilterEvent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FilterEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FilterEventsTable,
      FilterEvent,
      $$FilterEventsTableFilterComposer,
      $$FilterEventsTableOrderingComposer,
      $$FilterEventsTableAnnotationComposer,
      $$FilterEventsTableCreateCompanionBuilder,
      $$FilterEventsTableUpdateCompanionBuilder,
      (
        FilterEvent,
        BaseReferences<_$AppDatabase, $FilterEventsTable, FilterEvent>,
      ),
      FilterEvent,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RawSamplesTableTableManager get rawSamples =>
      $$RawSamplesTableTableManager(_db, _db.rawSamples);
  $$MinuteAggregatesTableTableManager get minuteAggregates =>
      $$MinuteAggregatesTableTableManager(_db, _db.minuteAggregates);
  $$HourAggregatesTableTableManager get hourAggregates =>
      $$HourAggregatesTableTableManager(_db, _db.hourAggregates);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$FilterEventsTableTableManager get filterEvents =>
      $$FilterEventsTableTableManager(_db, _db.filterEvents);
}
