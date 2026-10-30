import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/medicine.dart';
import '../../providers/medicine_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/confirm_dialog.dart';
import 'add_edit_medicine_screen.dart';

class MedicineDetailScreen extends StatelessWidget {
  final Medicine medicine;

  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final medProvider = Provider.of<MedicineProvider>(context);

    // Get live instance from provider if updated
    final liveMed = medProvider.allMedicines.firstWhere(
      (m) => m.id == medicine.id,
      orElse: () => medicine,
    );

    final nextDose = liveMed.getNextDoseTime();

    return Scaffold(
      appBar: AppBar(
        title: Text(liveMed.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditMedicineScreen(medicine: liveMed),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            onPressed: () async {
              final confirmed = await ConfirmDialog.show(
                context: context,
                title: 'Delete Medicine',
                message:
                    'Are you sure you want to delete ${liveMed.name}? All future notification reminders will be cancelled.',
                confirmLabel: 'Delete',
                isDestructive: true,
              );
              if (confirmed == true && context.mounted) {
                await medProvider.deleteMedicine(liveMed.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Status and Primary Info Card
            Container(
              padding: const EdgeInsets.all(20),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: liveMed.isActive
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          liveMed.isActive
                              ? 'Active Schedule'
                              : 'Schedule Completed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: liveMed.isActive
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                          ),
                        ),
                      ),
                      Switch(
                        value: liveMed.isActive,
                        onChanged: (val) async {
                          await medProvider.toggleActiveStatus(liveMed);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    liveMed.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${liveMed.dosageDisplay} • ${liveMed.form}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (nextDose != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.alarm_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Next Scheduled Dose',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  Formatters.formatDateTime(nextDose),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Schedule Details
            _SectionTitle(title: 'Schedule & Reminders'),
            _DetailCard(
              children: [
                _DetailRow(
                  label: 'Frequency',
                  value:
                      AppConstants.frequencyLabels[liveMed.frequency] ??
                      liveMed.frequency,
                  icon: Icons.repeat_rounded,
                ),
                const Divider(height: 20),
                _DetailRow(
                  label: 'Reminder Times',
                  value: liveMed.reminderTimes
                      .map(Formatters.formatTimeOfDay)
                      .join(', '),
                  icon: Icons.access_time_rounded,
                ),
                const Divider(height: 20),
                _DetailRow(
                  label: 'Days of Week',
                  value: Formatters.formatDaysList(liveMed.selectedDays),
                  icon: Icons.calendar_view_week_rounded,
                ),
                const Divider(height: 20),
                _DetailRow(
                  label: 'Duration',
                  value: liveMed.isOngoing
                      ? 'Ongoing (Started ${Formatters.formatDate(liveMed.startDate)})'
                      : '${Formatters.formatDate(liveMed.startDate)} – ${Formatters.formatDate(liveMed.endDate)}',
                  icon: Icons.date_range_rounded,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Clinical & Prescription Notes
            _SectionTitle(title: 'Prescription & Instructions'),
            _DetailCard(
              children: [
                _DetailRow(
                  label: 'Prescribing Doctor',
                  value:
                      liveMed.doctorName != null &&
                          liveMed.doctorName!.isNotEmpty
                      ? liveMed.doctorName!
                      : 'Not specified',
                  icon: Icons.person_rounded,
                ),
                const Divider(height: 20),
                _DetailRow(
                  label: 'Instructions',
                  value:
                      liveMed.instructions != null &&
                          liveMed.instructions!.isNotEmpty
                      ? liveMed.instructions!
                      : 'None provided',
                  icon: Icons.info_outline_rounded,
                ),
                if (liveMed.notes != null && liveMed.notes!.isNotEmpty) ...[
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Personal Notes',
                    value: liveMed.notes!,
                    icon: Icons.notes_rounded,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
