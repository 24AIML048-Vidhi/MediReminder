import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/dose_log_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/dose_card.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/permission_banner.dart';
import '../../widgets/stat_card.dart';
import '../medicines/add_edit_medicine_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToMedicines;
  final VoidCallback onNavigateToHistory;
  final VoidCallback onNavigateToHealth;

  const HomeScreen({
    super.key,
    required this.onNavigateToMedicines,
    required this.onNavigateToHistory,
    required this.onNavigateToHealth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final medProvider = Provider.of<MedicineProvider>(context);
    final doseProvider = Provider.of<DoseLogProvider>(context);

    final displayName =
        auth.userProfile?.displayName ?? auth.user?.displayName ?? 'User';
    final photoUrl = auth.userProfile?.photoUrl ?? auth.user?.photoURL;
    final today = DateTime.now();

    final todayItems = doseProvider.getDoseItemsForDate(
      today,
      medProvider.allMedicines,
    );
    final stats = doseProvider.getTodayStats(medProvider.allMedicines);
    final adherence = doseProvider.getTodayAdherence(medProvider.allMedicines);
    final activeCount = medProvider.activeMedicinesCount;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Trigger refresh
            final uid = auth.user?.uid;
            if (uid != null) {
              medProvider.bindUser(uid);
              doseProvider.bindUser(uid);
            }
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Header: Greeting, Today's Date, User Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Formatters.formatDate(today),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hello, $displayName 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.15,
                    ),
                    backgroundImage: photoUrl != null
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl == null
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Notification Permission Warning Banner if disabled
              const PermissionBanner(),

              // Quick Stat Cards Grid
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Active Meds',
                      value: '$activeCount',
                      icon: Icons.medication_rounded,
                      color: const Color(0xFF4F46E5),
                      onTap: onNavigateToMedicines,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Today\'s Adherence',
                      value: '${adherence.toInt()}%',
                      icon: Icons.trending_up_rounded,
                      color: adherence >= 80
                          ? const Color(0xFF10B981)
                          : (adherence >= 50
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFEF4444)),
                      onTap: onNavigateToHistory,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Taken Today',
                      value: '${stats['taken']}/${stats['total']}',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF10B981),
                      onTap: onNavigateToHistory,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Pending / Missed',
                      value:
                          '${(stats['pending'] ?? 0) + (stats['missed'] ?? 0)}',
                      icon: Icons.pending_actions_rounded,
                      color: (stats['missed'] ?? 0) > 0
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF59E0B),
                      subtitle: (stats['missed'] ?? 0) > 0
                          ? '${stats['missed']} missed'
                          : null,
                      onTap: onNavigateToHistory,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.add_rounded,
                      label: 'Add Med',
                      color: const Color(0xFF4F46E5),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddEditMedicineScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.history_rounded,
                      label: 'History',
                      color: const Color(0xFF06B6D4),
                      onTap: onNavigateToHistory,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.monitor_heart_outlined,
                      label: 'Health',
                      color: const Color(0xFF10B981),
                      onTap: onNavigateToHealth,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Today's Doses Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today\'s Schedule',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: onNavigateToMedicines,
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Doses List or Empty State
              if (medProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (todayItems.isEmpty)
                EmptyStateView(
                  icon: Icons.medication_liquid_outlined,
                  title: 'No medicines scheduled today',
                  description: 'Tap the button below to add your prescribed medicines and set reminders.',
                  actionLabel: 'Add Medicine',
                  onAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddEditMedicineScreen(),
                      ),
                    );
                  },
                )
              else
                ...todayItems.map(
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
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
