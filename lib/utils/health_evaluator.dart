import 'package:flutter/material.dart';

/// Evaluates health measurements against standard reference ranges.
/// Flags unusual values for user review without providing medical diagnoses.
class HealthEvaluator {
  static const String disclaimer =
      'These reference ranges are for general tracking purposes only and do not constitute a medical diagnosis. Always consult your qualified healthcare provider for personalized medical advice.';

  /// Systolic blood pressure evaluation (mmHg)
  static HealthStatus evaluateSystolic(int? systolic) {
    if (systolic == null) return HealthStatus.normal('Normal');
    if (systolic < 90) {
      return HealthStatus.warning('Low (<90 mmHg)', Colors.amber.shade700);
    } else if (systolic <= 120) {
      return HealthStatus.normal('Optimal (90–120 mmHg)');
    } else if (systolic <= 139) {
      return HealthStatus.warning(
        'Elevated (121–139 mmHg)',
        Colors.amber.shade700,
      );
    } else {
      return HealthStatus.danger('High (≥140 mmHg)', Colors.red.shade700);
    }
  }

  /// Diastolic blood pressure evaluation (mmHg)
  static HealthStatus evaluateDiastolic(int? diastolic) {
    if (diastolic == null) return HealthStatus.normal('Normal');
    if (diastolic < 60) {
      return HealthStatus.warning('Low (<60 mmHg)', Colors.amber.shade700);
    } else if (diastolic <= 80) {
      return HealthStatus.normal('Optimal (60–80 mmHg)');
    } else if (diastolic <= 89) {
      return HealthStatus.warning(
        'Elevated (81–89 mmHg)',
        Colors.amber.shade700,
      );
    } else {
      return HealthStatus.danger('High (≥90 mmHg)', Colors.red.shade700);
    }
  }

  /// Blood glucose evaluation (mg/dL)
  static HealthStatus evaluateBloodGlucose(double? glucose, String unit) {
    if (glucose == null) return HealthStatus.normal('Normal');
    final mgDl = unit == 'mmol/L' ? glucose * 18.0182 : glucose;

    if (mgDl < 70) {
      return HealthStatus.warning('Low (<70 mg/dL)', Colors.amber.shade700);
    } else if (mgDl <= 140) {
      return HealthStatus.normal('Normal (70–140 mg/dL)');
    } else if (mgDl <= 199) {
      return HealthStatus.warning(
        'Elevated (141–199 mg/dL)',
        Colors.amber.shade700,
      );
    } else {
      return HealthStatus.danger('High (≥200 mg/dL)', Colors.red.shade700);
    }
  }

  /// Temperature evaluation (°C)
  static HealthStatus evaluateTemperature(double? tempC) {
    if (tempC == null) return HealthStatus.normal('Normal');
    if (tempC < 35.5) {
      return HealthStatus.warning('Low (<35.5 °C)', Colors.amber.shade700);
    } else if (tempC <= 37.5) {
      return HealthStatus.normal('Normal (35.5–37.5 °C)');
    } else if (tempC <= 38.4) {
      return HealthStatus.warning(
        'Mild Fever (37.6–38.4 °C)',
        Colors.amber.shade700,
      );
    } else {
      return HealthStatus.danger('High Fever (≥38.5 °C)', Colors.red.shade700);
    }
  }

  /// Body Mass Index / Weight indicator
  static HealthStatus evaluateWeight(double? weightKg) {
    if (weightKg == null) return HealthStatus.normal('Normal');
    if (weightKg < 30 || weightKg > 250) {
      return HealthStatus.warning(
        'Please confirm weight',
        Colors.amber.shade700,
      );
    }
    return HealthStatus.normal('Recorded');
  }
}

class HealthStatus {
  final String label;
  final Color color;
  final bool isUnusual;

  const HealthStatus({
    required this.label,
    required this.color,
    required this.isUnusual,
  });

  factory HealthStatus.normal(String label) => HealthStatus(
    label: label,
    color: const Color(0xFF10B981),
    isUnusual: false,
  );

  factory HealthStatus.warning(String label, Color color) =>
      HealthStatus(label: label, color: color, isUnusual: true);

  factory HealthStatus.danger(String label, Color color) =>
      HealthStatus(label: label, color: color, isUnusual: true);
}
