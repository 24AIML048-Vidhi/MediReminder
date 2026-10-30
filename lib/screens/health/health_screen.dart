import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/health_record.dart';
import '../../providers/health_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/health_evaluator.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/health_chart.dart';
import 'add_edit_health_screen.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final healthProvider = Provider.of<HealthProvider>(context);

    final records = healthProvider.filteredRecords;
    final latest = healthProvider.latestRecord;

    return Scaffold(
      appBar: AppBar(title: const Text('Health Tracker')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Latest vitals quick overview
            if (latest != null) ...[
              const Text(
                'Latest Measurements',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _VitalChip(
                      label: 'Blood Pressure',
                      value: latest.bloodPressureDisplay ?? '—',
                      icon: Icons.favorite_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _VitalChip(
                      label: 'Blood Glucose',
                      value: latest.glucoseDisplay ?? '—',
                      icon: Icons.bloodtype_rounded,
                      color: const Color(0xFF06B6D4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _VitalChip(
                      label: 'Body Weight',
                      value: latest.weightDisplay ?? '—',
                      icon: Icons.monitor_weight_outlined,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _VitalChip(
                      label: 'Temperature',
                      value: latest.temperatureDisplay ?? '—',
                      icon: Icons.thermostat_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Trend Chart Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Measurement Trends',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      // Dropdown for metric chart
                      DropdownButton<String>(
                        value: healthProvider.selectedMetric == 'all'
                            ? 'bp'
                            : healthProvider.selectedMetric,
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'bp',
                            child: Text('Blood Pressure'),
                          ),
                          DropdownMenuItem(
                            value: 'glucose',
                            child: Text('Glucose'),
                          ),
                          DropdownMenuItem(
                            value: 'weight',
                            child: Text('Weight'),
                          ),
                          DropdownMenuItem(
                            value: 'temperature',
                            child: Text('Temperature'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            healthProvider.setSelectedMetric(val);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  HealthChart(
                    records: healthProvider.allRecords,
                    metric: healthProvider.selectedMetric == 'all'
                        ? 'bp'
                        : healthProvider.selectedMetric,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metric filter buttons row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _MetricFilterTab(
                    label: 'All Entries',
                    isSelected: healthProvider.selectedMetric == 'all',
                    onTap: () => healthProvider.setSelectedMetric('all'),
                  ),
                  const SizedBox(width: 8),
                  _MetricFilterTab(
                    label: 'Blood Pressure',
                    isSelected: healthProvider.selectedMetric == 'bp',
                    onTap: () => healthProvider.setSelectedMetric('bp'),
                  ),
                  const SizedBox(width: 8),
                  _MetricFilterTab(
                    label: 'Glucose',
                    isSelected: healthProvider.selectedMetric == 'glucose',
                    onTap: () => healthProvider.setSelectedMetric('glucose'),
                  ),
                  const SizedBox(width: 8),
                  _MetricFilterTab(
                    label: 'Weight',
                    isSelected: healthProvider.selectedMetric == 'weight',
                    onTap: () => healthProvider.setSelectedMetric('weight'),
                  ),
                  const SizedBox(width: 8),
                  _MetricFilterTab(
                    label: 'Temperature',
                    isSelected: healthProvider.selectedMetric == 'temperature',
                    onTap: () =>
                        healthProvider.setSelectedMetric('temperature'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Records List
            if (healthProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (records.isEmpty)
              EmptyStateView(
                icon: Icons.monitor_heart_outlined,
                title: 'No health entries yet',
                description: 'Record your vitals like blood pressure, blood glucose, weight, or temperature to track trends.',
                actionLabel: 'Log Measurement',
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddEditHealthScreen(),
                    ),
                  );
                },
              )
            else
              ...records.map(
                (record) => _HealthRecordCard(
                  record: record,
                  onEdit: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddEditHealthScreen(record: record),
                      ),
                    );
                  },
                  onDelete: () async {
                    final confirmed = await ConfirmDialog.show(
                      context: context,
                      title: 'Delete Health Entry',
                      message: 'Are you sure you want to delete this recorded vital entry?',
                      confirmLabel: 'Delete',
                      isDestructive: true,
                    );
                    if (confirmed == true) {
                      await healthProvider.deleteHealthRecord(record.id);
                    }
                  },
                ),
              ),
            const SizedBox(height: 60),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditHealthScreen()),
          );
        },
        tooltip: 'Log Vitals',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _VitalChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricFilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MetricFilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.primary
            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary
            : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
    );
  }
}

class _HealthRecordCard extends StatelessWidget {
  final HealthRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HealthRecordCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      Formatters.formatDateTime(record.dateTime),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (record.hasUnusualReading)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 13,
                              color: Color(0xFFD97706),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Review',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                if (record.bloodPressureDisplay != null)
                  _MeasurementMetric(
                    label: 'Blood Pressure',
                    value: record.bloodPressureDisplay!,
                    status: HealthEvaluator.evaluateSystolic(record.systolicBp),
                  ),
                if (record.glucoseDisplay != null)
                  _MeasurementMetric(
                    label: 'Blood Glucose',
                    value: record.glucoseDisplay!,
                    status: HealthEvaluator.evaluateBloodGlucose(
                      record.bloodGlucose,
                      record.bloodGlucoseUnit,
                    ),
                  ),
                if (record.weightDisplay != null)
                  _MeasurementMetric(
                    label: 'Weight',
                    value: record.weightDisplay!,
                    status: HealthEvaluator.evaluateWeight(record.weightKg),
                  ),
                if (record.temperatureDisplay != null)
                  _MeasurementMetric(
                    label: 'Temperature',
                    value: record.temperatureDisplay!,
                    status: HealthEvaluator.evaluateTemperature(
                      record.temperatureC,
                    ),
                  ),
              ],
            ),
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Notes: ${record.notes}',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MeasurementMetric extends StatelessWidget {
  final String label;
  final String value;
  final HealthStatus status;

  const _MeasurementMetric({
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        if (status.isUnusual)
          Text(
            status.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
      ],
    );
  }
}
