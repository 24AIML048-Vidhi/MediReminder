import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Security Architecture & Privacy Guidelines',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'MediReminder Mobile Application Development (MAD) Project',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const _SectionCard(
              title: '1. Strict User Isolation in SQLite',
              body:
                  'Every user registered locally is assigned an immutable, unique user ID. SQLite stores all records with explicit foreign key associations. No user can view or modify another user\'s prescriptions, dose logs, or health measurements on the device.',
            ),
            const SizedBox(height: 14),
            const _SectionCard(
              title: '2. Local-First SQLite Persistence',
              body:
                  'All sensitive medical and health data is saved directly in a local SQLite relational database on your device. Your data remains strictly on your device without transmitting personal details to third-party cloud servers.',
            ),
            const SizedBox(height: 14),
            const _SectionCard(
              title: '3. Local Device Notification Alarms',
              body:
                  'Reminders are scheduled locally on the client device using exact alarm APIs (flutter_local_notifications). Reminders trigger on schedule even when offline. Battery optimizations and Doze mode settings may affect exact alarm timing on certain OEM skins.',
            ),
            const SizedBox(height: 14),
            const _SectionCard(
              title: '4. Sensitive Health Data Protection',
              body:
                  'Vital measurements (blood pressure, blood glucose, temperature, and body weight) are treated as sensitive personal health data. Measurements are never shared or uploaded. Reference ranges provide tracking awareness and do not constitute a medical diagnosis.',
            ),
            const SizedBox(height: 14),
            const _SectionCard(
              title: '5. Right to Erasure (Account Deletion)',
              body:
                  'Users retain complete ownership over their data. Triggering "Delete Account and Local Data" permanently cascades and erases all prescription records, dose logs, health vitals, and profile records from the local SQLite database.',
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String body;

  const _SectionCard({required this.title, required this.body});

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
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
