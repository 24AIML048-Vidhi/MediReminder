import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_reminder/models/dose_log.dart';
import 'package:medi_reminder/models/health_record.dart';
import 'package:medi_reminder/models/medicine.dart';
import 'package:medi_reminder/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseService SQLite & Local Auth Tests', () {
    final dbService = DatabaseService();

    test('Initializes SQLite database schema successfully', () async {
      await dbService.init();
      final db = await dbService.database;
      expect(db.isOpen, isTrue);
    });

    test('Registers new user and prevents duplicate email registration', () async {
      const email = 'alex@example.com';
      const password = 'SecretPassword123!';
      const displayName = 'Alex Mercer';

      final user = await dbService.registerUser(
        email: email,
        password: password,
        displayName: displayName,
      );

      expect(user.uid.isNotEmpty, isTrue);
      expect(user.email, email);
      expect(user.displayName, displayName);

      // Verify profile and settings were created
      final profile = await dbService.getUserProfile(user.uid);
      expect(profile, isNotNull);
      expect(profile!.displayName, displayName);

      final settings = await dbService.getUserSettings(user.uid);
      expect(settings, isNotNull);
      expect(settings!.remindersEnabled, isTrue);

      // Verify duplicate registration fails
      expect(
        () => dbService.registerUser(
          email: email,
          password: 'AnotherPassword',
          displayName: 'Alex Duplicate',
        ),
        throwsA(contains('already exists')),
      );
    });

    test('Authenticates user with valid credentials and rejects bad password', () async {
      const email = 'alex@example.com';
      const password = 'SecretPassword123!';

      // Valid credentials
      final authenticated = await dbService.authenticateUser(
        email: email,
        password: password,
      );
      expect(authenticated.email, email);

      // Bad password
      expect(
        () => dbService.authenticateUser(
          email: email,
          password: 'WrongPassword!',
        ),
        throwsA(contains('Incorrect password')),
      );

      // Non-existent user
      expect(
        () => dbService.authenticateUser(
          email: 'unknown@example.com',
          password: password,
        ),
        throwsA(contains('No user found')),
      );
    });

    test('Performs Medicine CRUD with persistent SQLite storage', () async {
      final user = await dbService.authenticateUser(
        email: 'alex@example.com',
        password: 'SecretPassword123!',
      );

      final now = DateTime.now();
      final medicine = Medicine(
        id: 'med_sqlite_1',
        userId: user.uid,
        name: 'Amoxicillin',
        dosageAmount: 250,
        dosageUnit: 'mg',
        form: 'Capsule',
        instructions: 'Take with food',
        doctorName: 'Dr. John Watson',
        startDate: now,
        isOngoing: true,
        frequency: 'twice_daily',
        reminderTimes: const [
          TimeOfDay(hour: 9, minute: 0),
          TimeOfDay(hour: 21, minute: 0),
        ],
        selectedDays: const [1, 2, 3, 4, 5, 6, 7],
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // 1. Add Medicine
      final id = await dbService.addMedicine(medicine);
      expect(id, 'med_sqlite_1');

      // 2. Query Medicines
      var medicines = await dbService.getMedicines(user.uid);
      expect(medicines.any((m) => m.name == 'Amoxicillin'), isTrue);

      // 3. Update Medicine
      final updatedMed = medicine.copyWith(
        dosageAmount: 500,
        notes: 'Dose increased by physician',
      );
      await dbService.updateMedicine(updatedMed);

      medicines = await dbService.getMedicines(user.uid);
      final found = medicines.firstWhere((m) => m.id == 'med_sqlite_1');
      expect(found.dosageAmount, 500.0);
      expect(found.notes, 'Dose increased by physician');

      // 4. Delete Medicine
      await dbService.deleteMedicine(user.uid, 'med_sqlite_1');
      medicines = await dbService.getMedicines(user.uid);
      expect(medicines.any((m) => m.id == 'med_sqlite_1'), isFalse);
    });

    test('Records Dose Logs in SQLite and retrieves history', () async {
      final user = await dbService.authenticateUser(
        email: 'alex@example.com',
        password: 'SecretPassword123!',
      );

      final now = DateTime.now();
      final log = DoseLog(
        id: 'log_sqlite_1',
        userId: user.uid,
        medicineId: 'med_test',
        medicineName: 'Amoxicillin',
        dosage: '500 mg',
        scheduledTime: now,
        actionTime: now,
        status: 'taken',
        notes: 'Taken on time',
        createdAt: now,
      );

      await dbService.recordDoseLog(log);

      final logs = await dbService.getDoseLogs(user.uid);
      expect(logs.any((l) => l.id == 'log_sqlite_1' && l.isTaken), isTrue);

      await dbService.deleteDoseLog(user.uid, 'log_sqlite_1');
      final logsAfter = await dbService.getDoseLogs(user.uid);
      expect(logsAfter.any((l) => l.id == 'log_sqlite_1'), isFalse);
    });

    test('Records Health Records in SQLite and queries measurements', () async {
      final user = await dbService.authenticateUser(
        email: 'alex@example.com',
        password: 'SecretPassword123!',
      );

      final now = DateTime.now();
      final health = HealthRecord(
        id: 'health_sqlite_1',
        userId: user.uid,
        dateTime: now,
        weightKg: 72.5,
        systolicBp: 120,
        diastolicBp: 80,
        bloodGlucose: 95.0,
        bloodGlucoseUnit: 'mg/dL',
        temperatureC: 36.6,
        notes: 'Morning vitals check',
        createdAt: now,
      );

      final id = await dbService.addHealthRecord(health);
      expect(id, 'health_sqlite_1');

      final records = await dbService.getHealthRecords(user.uid);
      expect(records.any((r) => r.id == 'health_sqlite_1'), isTrue);

      final rec = records.firstWhere((r) => r.id == 'health_sqlite_1');
      expect(rec.systolicBp, 120);
      expect(rec.bloodPressureDisplay, '120/80 mmHg');

      await dbService.deleteHealthRecord(user.uid, 'health_sqlite_1');
      final after = await dbService.getHealthRecords(user.uid);
      expect(after.any((r) => r.id == 'health_sqlite_1'), isFalse);
    });

    test('Permanently deletes all user data and cascading records', () async {
      final user = await dbService.authenticateUser(
        email: 'alex@example.com',
        password: 'SecretPassword123!',
      );

      // Add one of each record
      final now = DateTime.now();
      await dbService.addMedicine(
        Medicine(
          id: 'cascade_med',
          userId: user.uid,
          name: 'Cascade Med',
          dosageAmount: 10,
          dosageUnit: 'mg',
          form: 'Tablet',
          startDate: now,
          frequency: 'once_daily',
          reminderTimes: const [TimeOfDay(hour: 8, minute: 0)],
          createdAt: now,
          updatedAt: now,
        ),
      );

      await dbService.recordDoseLog(
        DoseLog(
          id: 'cascade_log',
          userId: user.uid,
          medicineId: 'cascade_med',
          medicineName: 'Cascade Med',
          dosage: '10 mg',
          scheduledTime: now,
          status: 'taken',
          createdAt: now,
        ),
      );

      // Delete all data
      await dbService.deleteAllUserData(user.uid);

      // Verify cascading deletions
      final meds = await dbService.getMedicines(user.uid);
      final logs = await dbService.getDoseLogs(user.uid);
      final profile = await dbService.getUserProfile(user.uid);
      final userRecord = await dbService.getUserById(user.uid);

      expect(meds.isEmpty, isTrue);
      expect(logs.isEmpty, isTrue);
      expect(profile, isNull);
      expect(userRecord, isNull);
    });
  });
}
