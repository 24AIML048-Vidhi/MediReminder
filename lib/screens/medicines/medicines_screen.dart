import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/medicine.dart';
import '../../providers/medicine_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import 'add_edit_medicine_screen.dart';
import 'medicine_detail_screen.dart';

class MedicinesScreen extends StatelessWidget {
  const MedicinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final medProvider = Provider.of<MedicineProvider>(context);

    final medicines = medProvider.filteredMedicines;

    return Scaffold(
      appBar: AppBar(title: const Text('My Medicines')),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => medProvider.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Search medicine, doctor, instruction...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: medProvider.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => medProvider.setSearchQuery(''),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips (Active, Completed, All)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label:
                              'Active (${medProvider.allMedicines.where((m) => m.isActive).length})',
                          isSelected: medProvider.filter == 'active',
                          onTap: () => medProvider.setFilter('active'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label:
                              'Completed (${medProvider.allMedicines.where((m) => !m.isActive).length})',
                          isSelected: medProvider.filter == 'completed',
                          onTap: () => medProvider.setFilter('completed'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'All (${medProvider.allMedicines.length})',
                          isSelected: medProvider.filter == 'all',
                          onTap: () => medProvider.setFilter('all'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Medicine List or Empty State
            Expanded(
              child: medProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : medicines.isEmpty
                  ? EmptyStateView(
                      icon: Icons.medication_rounded,
                      title: medProvider.searchQuery.isNotEmpty
                          ? 'No matching medicines found'
                          : 'No medicines in this category',
                      description: medProvider.searchQuery.isNotEmpty
                          ? 'Try searching with a different medication name or clear your search query.'
                          : 'Add your prescribed medicines to set reminders and track adherence.',
                      actionLabel: medProvider.searchQuery.isEmpty
                          ? 'Add Medicine'
                          : null,
                      onAction: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddEditMedicineScreen(),
                          ),
                        );
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: medicines.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final medicine = medicines[index];
                        return _MedicineListItem(
                          medicine: medicine,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    MedicineDetailScreen(medicine: medicine),
                              ),
                            );
                          },
                          onEdit: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddEditMedicineScreen(medicine: medicine),
                              ),
                            );
                          },
                          onDelete: () async {
                            final confirmed = await ConfirmDialog.show(
                              context: context,
                              title: 'Delete Medicine',
                              message:
                                  'Are you sure you want to delete ${medicine.name}? Scheduled reminders for this medicine will be cancelled.',
                              confirmLabel: 'Delete',
                              isDestructive: true,
                            );
                            if (confirmed == true && context.mounted) {
                              await medProvider.deleteMedicine(medicine.id);
                            }
                          },
                          onToggleActive: () async {
                            await medProvider.toggleActiveStatus(medicine);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ChoiceChip(
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _MedicineListItem extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _MedicineListItem({
    required this.medicine,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nextDose = medicine.getNextDoseTime();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                      color: medicine.isActive
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.medication_rounded,
                      color: medicine.isActive
                          ? theme.colorScheme.primary
                          : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            decoration: medicine.isActive
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${medicine.dosageDisplay} • ${medicine.form}',
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    onSelected: (val) {
                      if (val == 'edit') onEdit();
                      if (val == 'delete') onDelete();
                      if (val == 'toggle') onToggleActive();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: const Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              medicine.isActive
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              medicine.isActive
                                  ? 'Mark as Completed'
                                  : 'Activate Schedule',
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Color(0xFFEF4444),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Delete',
                              style: TextStyle(color: Color(0xFFEF4444)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  // Frequency Chip
                  _InfoChip(
                    icon: Icons.repeat_rounded,
                    label: medicine.reminderTimes.length == 1
                        ? 'Once daily'
                        : '${medicine.reminderTimes.length} times daily',
                  ),
                  // Next Dose Chip
                  if (medicine.isActive && nextDose != null)
                    _InfoChip(
                      icon: Icons.alarm_rounded,
                      label: 'Next: ${Formatters.formatTime(nextDose)}',
                      isHighlight: true,
                    ),
                  // Completed Chip if inactive
                  if (!medicine.isActive)
                    const _InfoChip(
                      icon: Icons.check_circle_outline,
                      label: 'Completed',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHighlight;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isHighlight
                ? theme.colorScheme.primary
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isHighlight
                  ? theme.colorScheme.primary
                  : (isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}
