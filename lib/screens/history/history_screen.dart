import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dose_log_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/adherence_chart.dart';
import '../../widgets/dose_card.dart';
import '../../widgets/empty_state_view.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final doseProvider = Provider.of<DoseLogProvider>(context);
    final medProvider = Provider.of<MedicineProvider>(context);

    final selectedDate = doseProvider.selectedDate;
    final items = doseProvider.getDoseItemsForDate(
      selectedDate,
      medProvider.allMedicines,
    );
    final past7DaysData = doseProvider.getPast7DaysAdherence(
      medProvider.allMedicines,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Medication History')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Past 7 Days Adherence Chart Card
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
                        'Weekly Adherence Trend',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Last 7 Days',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AdherenceChart(data: past7DaysData),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Date Navigator Bar (Previous Day, Date Picker, Next Day)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      doseProvider.setSelectedDate(
                        selectedDate.subtract(const Duration(days: 1)),
                      );
                    },
                    tooltip: 'Previous Day',
                  ),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        doseProvider.setSelectedDate(picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            Formatters.formatDate(selectedDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () {
                      doseProvider.setSelectedDate(
                        selectedDate.add(const Duration(days: 1)),
                      );
                    },
                    tooltip: 'Next Day',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Important Health Notice on Missed Doses
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How Missed Doses Work',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'A dose is automatically marked as missed if its scheduled time has elapsed today without being marked as taken. Never double a dose to make up for a missed one unless explicitly advised by your doctor.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1E3A8A),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dose items for selected date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Doses for ${Formatters.formatShortDate(selectedDate)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${items.where((i) => i.isTaken).length}/${items.length} taken',
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
            const SizedBox(height: 12),

            if (items.isEmpty)
              EmptyStateView(
                icon: Icons.event_available_outlined,
                title: 'No doses scheduled',
                description:
                    'No medications were scheduled for this selected date.',
              )
            else
              ...items.map(
                (item) => DoseCard(
                  item: item,
                  onStatusChange: (status) async {
                    await doseProvider.markDoseStatus(
                      item: item,
                      status: status,
                    );
                  },
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
