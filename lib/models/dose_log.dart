/// Log entry recording whether a scheduled medicine dose was taken, skipped, or missed.
class DoseLog {
  final String id;
  final String userId;
  final String medicineId;
  final String medicineName;
  final String dosage;
  final DateTime scheduledTime;
  final DateTime? actionTime;
  final String status; // 'taken', 'skipped', 'missed'
  final String? notes;
  final DateTime createdAt;

  const DoseLog({
    required this.id,
    required this.userId,
    required this.medicineId,
    required this.medicineName,
    required this.dosage,
    required this.scheduledTime,
    this.actionTime,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  bool get isTaken => status == 'taken';
  bool get isSkipped => status == 'skipped';
  bool get isMissed => status == 'missed';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'dosage': dosage,
      'scheduledTime': scheduledTime.toIso8601String(),
      'actionTime': actionTime?.toIso8601String(),
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DoseLog.fromMap(Map<String, dynamic> map, String docId) {
    return DoseLog(
      id: docId.isNotEmpty ? docId : (map['id'] as String? ?? ''),
      userId: map['userId'] as String? ?? '',
      medicineId: map['medicineId'] as String? ?? '',
      medicineName: map['medicineName'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      scheduledTime: map['scheduledTime'] != null
          ? DateTime.tryParse(map['scheduledTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      actionTime: map['actionTime'] != null
          ? DateTime.tryParse(map['actionTime'].toString())
          : null,
      status: map['status'] as String? ?? 'missed',
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  DoseLog copyWith({
    String? id,
    String? userId,
    String? medicineId,
    String? medicineName,
    String? dosage,
    DateTime? scheduledTime,
    DateTime? actionTime,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return DoseLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actionTime: actionTime ?? this.actionTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
