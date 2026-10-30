import 'package:flutter/material.dart';

import '../providers/dose_log_provider.dart';
import '../utils/formatters.dart';

class DoseCard extends StatelessWidget {
  final ScheduledDoseItem item;
  final Function(String status)? onStatusChange;
  final VoidCallback? onTap;

  const DoseCard({
    super.key,
    required this.item,
    this.onStatusChange,
    this.onTap,
  });

  IconData _getMedicineIcon(String form) {
    switch (form.toLowerCase()) {
      case 'capsule':
        return Icons.medication_liquid;
      case 'syrup':
        return Icons.local_drink;
      case 'injection':
        return Icons.vaccines;
      case 'drops':
        return Icons.opacity;
      case 'inhaler':
        return Icons.air;
      default:
        return Icons.medication;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (item.isTaken) {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'Taken';
      statusIcon = Icons.check_circle_rounded;
    } else if (item.isSkipped) {
      statusColor = const Color(0xFF64748B);
      statusLabel = 'Skipped';
      statusIcon = Icons.cancel_outlined;
    } else if (item.isMissed) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'Missed';
      statusIcon = Icons.error_outline_rounded;
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'Pending';
      statusIcon = Icons.schedule_rounded;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: item.isTaken
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: item.isTaken ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getMedicineIcon(item.medicine.form),
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.medicine.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item.medicine.dosageDisplay} • ${item.medicine.form}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Time and instructions
              Row(
                children: [
                  Icon(
                    Icons.access_time_filled,
                    size: 15,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    Formatters.formatTime(item.scheduledDateTime),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  if (item.medicine.instructions != null &&
                      item.medicine.instructions!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    const Text('•'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.medicine.instructions!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // Action buttons (if not yet taken or user wants to update)
              if (onStatusChange != null) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onStatusChange!('skipped'),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Skip'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => onStatusChange!('taken'),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(item.isTaken ? 'Taken ✓' : 'Mark as Taken'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          backgroundColor: item.isTaken
                              ? const Color(0xFF10B981)
                              : theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
