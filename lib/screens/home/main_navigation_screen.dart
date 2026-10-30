import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/dose_log_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/medicine_provider.dart';
import '../health/health_screen.dart';
import '../history/history_screen.dart';
import '../medicines/add_edit_medicine_screen.dart';
import '../medicines/medicines_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  String? _lastBoundUid;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncUserWithProviders();
  }

  void _syncUserWithProviders() {
    final auth = Provider.of<AuthProvider>(context);
    final currentUid = auth.user?.uid;

    if (currentUid != _lastBoundUid) {
      _lastBoundUid = currentUid;

      final medProvider = Provider.of<MedicineProvider>(context, listen: false);
      final doseProvider = Provider.of<DoseLogProvider>(context, listen: false);
      final healthProvider = Provider.of<HealthProvider>(
        context,
        listen: false,
      );

      medProvider.bindUser(currentUid);
      doseProvider.bindUser(currentUid);
      healthProvider.bindUser(currentUid);
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onNavigateToMedicines: () => _onTabSelected(1),
        onNavigateToHistory: () => _onTabSelected(2),
        onNavigateToHealth: () => _onTabSelected(3),
      ),
      const MedicinesScreen(),
      const HistoryScreen(),
      const HealthScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication_rounded),
            label: 'Medicines',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_toggle_off_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddEditMedicineScreen(),
                  ),
                );
              },
              tooltip: 'Add Medicine',
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }
}
