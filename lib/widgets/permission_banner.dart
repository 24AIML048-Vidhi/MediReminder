import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class PermissionBanner extends StatefulWidget {
  const PermissionBanner({super.key});

  @override
  State<PermissionBanner> createState() => _PermissionBannerState();
}

class _PermissionBannerState extends State<PermissionBanner> {
  bool _notificationsEnabled = true;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final enabled = await NotificationService().areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _checked = true;
      });
    }
  }

  Future<void> _requestPermission() async {
    final granted = await NotificationService().requestPermissions();
    if (mounted) {
      setState(() {
        _notificationsEnabled = granted;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted ? 'Medicine notifications are now active!' : 'Permission was not granted. You can enable notifications in device settings.',
          ),
          backgroundColor: granted
              ? const Color(0xFF10B981)
              : const Color(0xFFF59E0B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || _notificationsEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_off_rounded,
            color: Color(0xFFD97706),
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications are disabled',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Enable notifications to receive timely dose alerts on time.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _requestPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }
}
