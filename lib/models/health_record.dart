import '../utils/health_evaluator.dart';

/// Health record capturing optional vital measurements.
class HealthRecord {
  final String id;
  final String userId;
  final DateTime dateTime;
  final double? weightKg;
  final int? systolicBp;
  final int? diastolicBp;
  final double? bloodGlucose;
  final String bloodGlucoseUnit; // 'mg/dL' or 'mmol/L'
  final double? temperatureC;
  final String? notes;
  final DateTime createdAt;

  const HealthRecord({
    required this.id,
    required this.userId,
    required this.dateTime,
    this.weightKg,
    this.systolicBp,
    this.diastolicBp,
    this.bloodGlucose,
    this.bloodGlucoseUnit = 'mg/dL',
    this.temperatureC,
    this.notes,
    required this.createdAt,
  });

  /// Blood pressure formatted string (e.g. "120/80 mmHg")
  String? get bloodPressureDisplay {
    if (systolicBp != null && diastolicBp != null) {
      return '$systolicBp/$diastolicBp mmHg';
    } else if (systolicBp != null) {
      return '$systolicBp mmHg (Sys)';
    } else if (diastolicBp != null) {
      return '$diastolicBp mmHg (Dia)';
    }
    return null;
  }

  /// Blood glucose formatted string
  String? get glucoseDisplay {
    if (bloodGlucose == null) return null;
    final val = bloodGlucose! % 1 == 0
        ? bloodGlucose!.toInt().toString()
        : bloodGlucose!.toStringAsFixed(1);
    return '$val $bloodGlucoseUnit';
  }

  /// Weight formatted string
  String? get weightDisplay {
    if (weightKg == null) return null;
    final val = weightKg! % 1 == 0
        ? weightKg!.toInt().toString()
        : weightKg!.toStringAsFixed(1);
    return '$val kg';
  }

  /// Temperature formatted string
  String? get temperatureDisplay {
    if (temperatureC == null) return null;
    return '${temperatureC!.toStringAsFixed(1)} °C';
  }

  /// Whether any entered value in this entry flags an unusual reading
  bool get hasUnusualReading {
    if (systolicBp != null &&
        HealthEvaluator.evaluateSystolic(systolicBp).isUnusual) {
      return true;
    }
    if (diastolicBp != null &&
        HealthEvaluator.evaluateDiastolic(diastolicBp).isUnusual) {
      return true;
    }
    if (bloodGlucose != null &&
        HealthEvaluator.evaluateBloodGlucose(
          bloodGlucose,
          bloodGlucoseUnit,
        ).isUnusual) {
      return true;
    }
    if (temperatureC != null &&
        HealthEvaluator.evaluateTemperature(temperatureC).isUnusual) {
      return true;
    }
    return false;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'dateTime': dateTime.toIso8601String(),
      'weightKg': weightKg,
      'systolicBp': systolicBp,
      'diastolicBp': diastolicBp,
      'bloodGlucose': bloodGlucose,
      'bloodGlucoseUnit': bloodGlucoseUnit,
      'temperatureC': temperatureC,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HealthRecord.fromMap(Map<String, dynamic> map, String docId) {
    return HealthRecord(
      id: docId.isNotEmpty ? docId : (map['id'] as String? ?? ''),
      userId: map['userId'] as String? ?? '',
      dateTime: map['dateTime'] != null
          ? DateTime.tryParse(map['dateTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      systolicBp: (map['systolicBp'] as num?)?.toInt(),
      diastolicBp: (map['diastolicBp'] as num?)?.toInt(),
      bloodGlucose: (map['bloodGlucose'] as num?)?.toDouble(),
      bloodGlucoseUnit: map['bloodGlucoseUnit'] as String? ?? 'mg/dL',
      temperatureC: (map['temperatureC'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  HealthRecord copyWith({
    String? id,
    String? userId,
    DateTime? dateTime,
    double? weightKg,
    int? systolicBp,
    int? diastolicBp,
    double? bloodGlucose,
    String? bloodGlucoseUnit,
    double? temperatureC,
    String? notes,
    DateTime? createdAt,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dateTime: dateTime ?? this.dateTime,
      weightKg: weightKg ?? this.weightKg,
      systolicBp: systolicBp ?? this.systolicBp,
      diastolicBp: diastolicBp ?? this.diastolicBp,
      bloodGlucose: bloodGlucose ?? this.bloodGlucose,
      bloodGlucoseUnit: bloodGlucoseUnit ?? this.bloodGlucoseUnit,
      temperatureC: temperatureC ?? this.temperatureC,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
