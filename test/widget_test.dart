import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_reminder/models/dose_log.dart';
import 'package:medi_reminder/models/health_record.dart';
import 'package:medi_reminder/models/medicine.dart';
import 'package:medi_reminder/models/user_profile.dart';
import 'package:medi_reminder/providers/dose_log_provider.dart';
import 'package:medi_reminder/utils/formatters.dart';
import 'package:medi_reminder/utils/health_evaluator.dart';
import 'package:medi_reminder/widgets/custom_text_field.dart';
import 'package:medi_reminder/widgets/dose_card.dart';
import 'package:medi_reminder/widgets/empty_state_view.dart';
import 'package:medi_reminder/widgets/stat_card.dart';

void main() {
  group('Medicine Model Unit Tests', () {
    test('Medicine model serializes and deserializes correctly', () {
      final now = DateTime(2026, 10, 28, 8, 0);
      final medicine = Medicine(
        id: 'med_123',
        userId: 'user_456',
        name: 'Metformin',
        dosageAmount: 500,
        dosageUnit: 'mg',
        form: 'Tablet',
        instructions: 'Take after meals',
        doctorName: 'Dr. Jane Smith',
        startDate: now,
        isOngoing: true,
        frequency: 'twice_daily',
        reminderTimes: const [
          TimeOfDay(hour: 8, minute: 0),
          TimeOfDay(hour: 20, minute: 0),
        ],
        selectedDays: const [1, 2, 3, 4, 5],
        notes: 'Keep in cool dry place',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = medicine.toMap();
      expect(map['id'], 'med_123');
      expect(map['name'], 'Metformin');
      expect(map['dosageAmount'], 500.0);
      expect(map['dosageUnit'], 'mg');
      expect(map['reminderTimes'], ['08:00', '20:00']);

      final reconstructed = Medicine.fromMap(map, 'med_123');
      expect(reconstructed.id, medicine.id);
      expect(reconstructed.name, medicine.name);
      expect(reconstructed.dosageDisplay, '500 mg');
      expect(reconstructed.reminderTimes.length, 2);
      expect(reconstructed.isScheduledOnWeekday(1), true); // Monday
      expect(reconstructed.isScheduledOnWeekday(6), false); // Saturday
    });

    test('Medicine getNotificationId generates stable positive hash', () {
      final medicine = Medicine(
        id: 'med_test_id',
        userId: 'uid_test',
        name: 'Aspirin',
        dosageAmount: 100,
        dosageUnit: 'mg',
        form: 'Tablet',
        startDate: DateTime.now(),
        frequency: 'once_daily',
        reminderTimes: const [TimeOfDay(hour: 9, minute: 0)],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final hash0 = medicine.getNotificationId(0);
      final hash0Again = medicine.getNotificationId(0);
      final hash1 = medicine.getNotificationId(1);

      expect(hash0, greaterThanOrEqualTo(0));
      expect(hash0, equals(hash0Again));
      expect(hash0, isNot(equals(hash1)));
    });
  });

  group('Health Evaluator Clinical Range Tests', () {
    test('Evaluates systolic blood pressure correctly', () {
      expect(HealthEvaluator.evaluateSystolic(115).isUnusual, false);
      expect(HealthEvaluator.evaluateSystolic(85).isUnusual, true);
      expect(HealthEvaluator.evaluateSystolic(145).isUnusual, true);
    });

    test('Evaluates blood glucose correctly', () {
      expect(
        HealthEvaluator.evaluateBloodGlucose(95, 'mg/dL').isUnusual,
        false,
      );
      expect(HealthEvaluator.evaluateBloodGlucose(55, 'mg/dL').isUnusual, true);
      expect(
        HealthEvaluator.evaluateBloodGlucose(220, 'mg/dL').isUnusual,
        true,
      );
    });

    test('Evaluates temperature correctly', () {
      expect(HealthEvaluator.evaluateTemperature(36.8).isUnusual, false);
      expect(HealthEvaluator.evaluateTemperature(38.8).isUnusual, true);
      expect(HealthEvaluator.evaluateTemperature(34.5).isUnusual, true);
    });
  });

  group('HealthRecord Model Tests', () {
    test('Flags unusual readings correctly', () {
      final normalRecord = HealthRecord(
        id: 'hr_1',
        userId: 'user_1',
        dateTime: DateTime.now(),
        systolicBp: 120,
        diastolicBp: 80,
        bloodGlucose: 100,
        temperatureC: 36.6,
        createdAt: DateTime.now(),
      );
      expect(normalRecord.hasUnusualReading, false);
      expect(normalRecord.bloodPressureDisplay, '120/80 mmHg');

      final highBpRecord = HealthRecord(
        id: 'hr_2',
        userId: 'user_1',
        dateTime: DateTime.now(),
        systolicBp: 155,
        diastolicBp: 95,
        createdAt: DateTime.now(),
      );
      expect(highBpRecord.hasUnusualReading, true);
    });
  });

  group('DoseLog and ScheduledDoseItem Tests', () {
    test('Deterministic log ID is consistent', () {
      final med = Medicine(
        id: 'med_abc',
        userId: 'user_abc',
        name: 'Vitamin D',
        dosageAmount: 1000,
        dosageUnit: 'unit(s)',
        form: 'Capsule',
        startDate: DateTime(2026, 1, 1),
        frequency: 'once_daily',
        reminderTimes: const [TimeOfDay(hour: 9, minute: 0)],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final item = ScheduledDoseItem(
        medicine: med,
        timeIndex: 0,
        scheduledDateTime: DateTime(2026, 10, 28, 9, 0),
      );

      expect(item.deterministicLogId, 'med_abc_2026_10_28_0');
    });

    test('DoseLog status helpers work as expected', () {
      final log = DoseLog(
        id: 'log_1',
        userId: 'user_1',
        medicineId: 'med_1',
        medicineName: 'Amoxicillin',
        dosage: '500 mg',
        scheduledTime: DateTime(2026, 10, 28, 8, 0),
        status: 'taken',
        createdAt: DateTime(2026, 10, 28, 8, 5),
      );

      expect(log.isTaken, true);
      expect(log.isSkipped, false);
      expect(log.isMissed, false);
    });
  });

  group('UserProfile Model Tests', () {
    test('Serializes and deserializes user profile', () {
      final profile = UserProfile(
        userId: 'test_uid_99',
        email: 'doctor@hospital.org',
        displayName: 'Dr. John',
        photoUrl: 'https://example.com/avatar.jpg',
        createdAt: DateTime(2026, 5, 1),
        lastLoginAt: DateTime(2026, 10, 28),
      );

      final map = profile.toMap();
      final loaded = UserProfile.fromMap(map, 'test_uid_99');

      expect(loaded.userId, 'test_uid_99');
      expect(loaded.email, 'doctor@hospital.org');
      expect(loaded.displayName, 'Dr. John');
    });
  });

  group('Formatters Unit Tests', () {
    test('Formats date and times consistently', () {
      final dt = DateTime(2026, 10, 28, 14, 30);
      expect(Formatters.formatTime(dt), '02:30 PM');
      expect(Formatters.formatDate(dt), 'Oct 28, 2026');
      expect(Formatters.weekdayName(3), 'Wed');
      expect(Formatters.formatDosage(2.0, 'tablets'), '2 tablets');
      expect(Formatters.formatDosage(2.5, 'ml'), '2.5 ml');
      expect(Formatters.formatDaysList([1, 3, 5]), 'Mon, Wed, Fri');
      expect(Formatters.formatDaysList([]), 'Every day');
    });
  });

  group('Widget Tests', () {
    testWidgets('StatCard renders title, value, and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Active Meds',
              value: '5',
              icon: Icons.medication,
              color: Colors.blue,
              subtitle: '2 today',
            ),
          ),
        ),
      );

      expect(find.text('Active Meds'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('2 today'), findsOneWidget);
      expect(find.byIcon(Icons.medication), findsOneWidget);
    });

    testWidgets(
      'EmptyStateView renders title, description, and action button',
      (tester) async {
        bool actionTapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyStateView(
                icon: Icons.medical_services,
                title: 'No medicines found',
                description: 'Add your first prescription to get started.',
                actionLabel: 'Add Now',
                onAction: () => actionTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('No medicines found'), findsOneWidget);
        expect(
          find.text('Add your first prescription to get started.'),
          findsOneWidget,
        );
        expect(find.text('Add Now'), findsOneWidget);

        await tester.tap(find.text('Add Now'));
        expect(actionTapped, true);
      },
    );

    testWidgets('CustomTextField accepts text and renders validation', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: controller,
              label: 'Medicine Name',
              hint: 'Enter name',
              prefixIcon: Icons.medication,
            ),
          ),
        ),
      );

      expect(find.text('Medicine Name'), findsOneWidget);
      expect(find.text('Enter name'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Paracetamol');
      expect(controller.text, 'Paracetamol');
    });

    testWidgets('DoseCard displays medicine details and status badge', (
      tester,
    ) async {
      final med = Medicine(
        id: 'med_test',
        userId: 'uid_test',
        name: 'Ibuprofen',
        dosageAmount: 400,
        dosageUnit: 'mg',
        form: 'Tablet',
        instructions: 'Take with food',
        startDate: DateTime(2026, 1, 1),
        frequency: 'once_daily',
        reminderTimes: const [TimeOfDay(hour: 8, minute: 0)],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final item = ScheduledDoseItem(
        medicine: med,
        timeIndex: 0,
        scheduledDateTime: DateTime(2026, 10, 28, 8, 0),
        log: DoseLog(
          id: 'log_test',
          userId: 'uid_test',
          medicineId: 'med_test',
          medicineName: 'Ibuprofen',
          dosage: '400 mg',
          scheduledTime: DateTime(2026, 10, 28, 8, 0),
          status: 'taken',
          createdAt: DateTime(2026, 10, 28, 8, 5),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DoseCard(item: item)),
        ),
      );

      expect(find.text('Ibuprofen'), findsOneWidget);
      expect(find.text('400 mg • Tablet'), findsOneWidget);
      expect(find.text('Taken'), findsOneWidget);
      expect(find.text('Take with food'), findsOneWidget);
    });
  });
}
