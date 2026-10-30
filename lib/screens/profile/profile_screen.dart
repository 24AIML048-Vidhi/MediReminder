import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/dose_log_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../auth/welcome_screen.dart';
import 'privacy_policy_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditNameDialog(BuildContext context, AuthProvider auth) {
    final controller = TextEditingController(
      text: auth.userProfile?.displayName ?? auth.user?.displayName ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await auth.updateDisplayName(controller.text.trim());
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final displayName =
        auth.userProfile?.displayName ?? auth.user?.displayName ?? 'User';
    final email = auth.userProfile?.email ?? auth.user?.email ?? 'No email';
    final photoUrl = auth.userProfile?.photoUrl ?? auth.user?.photoURL;
    final uid = auth.user?.uid ?? 'N/A';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // User Profile Card
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
                children: [
                  CircleAvatar(
                    radius: 36,
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
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _showEditNameDialog(context, auth),
                        tooltip: 'Edit name',
                      ),
                    ],
                  ),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'UID: ${uid.length > 12 ? "${uid.substring(0, 10)}..." : uid}',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Group: Notifications & Alerts
            const _SettingsHeader(title: 'Notification Preferences'),
            Container(
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
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Reminder Sound',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Play sound when medicine alarms fire',
                    ),
                    value: themeProvider.soundEnabled,
                    onChanged: (val) => themeProvider.setSoundEnabled(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Vibration',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Vibrate device on dose alerts'),
                    value: themeProvider.vibrationEnabled,
                    onChanged: (val) => themeProvider.setVibrationEnabled(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Group: Appearance / Theme
            const _SettingsHeader(title: 'Appearance'),
            Container(
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
                children: [
                  ListTile(
                    title: const Text(
                      'Theme Mode',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      themeProvider.themeMode == ThemeMode.system
                          ? 'System Default'
                          : (themeProvider.themeMode == ThemeMode.dark
                                ? 'Dark Theme'
                                : 'Light Theme'),
                    ),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeProvider.themeMode,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) themeProvider.setThemeMode(mode);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Group: Information & Security
            const _SettingsHeader(title: 'About & Security'),
            Container(
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
                children: [
                  ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: const Text(
                      'Privacy & Security Policy',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'SQLite isolation and data protection',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.school_outlined),
                    title: Text(
                      'Project Scope',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Mobile Application Development (MAD) Academic Project',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sign Out Button
            OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await ConfirmDialog.show(
                  context: context,
                  title: 'Sign Out',
                  message: 'Are you sure you want to sign out of MediReminder?',
                  confirmLabel: 'Sign Out',
                );

                if (confirmed == true && context.mounted) {
                  // Clear in-memory caches and notification listeners
                  Provider.of<MedicineProvider>(context, listen: false).clear();
                  Provider.of<DoseLogProvider>(context, listen: false).clear();
                  Provider.of<HealthProvider>(context, listen: false).clear();

                  await auth.signOut();

                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                      (route) => false,
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),

            // Delete Account Button (Red / Destructive)
            TextButton.icon(
              onPressed: () async {
                final confirmed = await ConfirmDialog.show(
                  context: context,
                  title: 'Delete Account Permanently',
                  message: 'CAUTION: This will permanently delete your MediReminder account, all prescribed medication records, dose tracking history, and recorded health vitals from the local SQLite database. This action cannot be undone.\n\nDo you wish to proceed?',
                  confirmLabel: 'Delete Forever',
                  cancelLabel: 'Keep Account',
                  isDestructive: true,
                );

                if (confirmed == true && context.mounted) {
                  // Clear in-memory caches
                  Provider.of<MedicineProvider>(context, listen: false).clear();
                  Provider.of<DoseLogProvider>(context, listen: false).clear();
                  Provider.of<HealthProvider>(context, listen: false).clear();

                  final success = await auth.deleteAccount();

                  if (success && context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                      (route) => false,
                    );
                  } else if (auth.errorMessage != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(auth.errorMessage!),
                        backgroundColor: const Color(0xFFEF4444),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              label: const Text(
                'Delete Account and Cloud Data',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final String title;
  const _SettingsHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}
