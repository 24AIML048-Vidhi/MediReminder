import 'dart:async';

import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

/// Provider managing medicines list, filters, search, and notification synchronization.
class MedicineProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  final NotificationService _notificationService;

  List<Medicine> _medicines = [];
  String _searchQuery = '';
  String _filter = 'active'; // 'active', 'completed', 'all'
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Medicine>>? _medicineSubscription;
  String? _currentUserId;

  MedicineProvider({
    DatabaseService? databaseService,
    NotificationService? notificationService,
  }) : _databaseService = databaseService ?? DatabaseService(),
       _notificationService = notificationService ?? NotificationService();

  List<Medicine> get allMedicines => _medicines;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get filter => _filter;

  /// Filtered list of medicines based on active status and search query
  List<Medicine> get filteredMedicines {
    return _medicines.where((med) {
      // Filter status
      if (_filter == 'active' && !med.isActive) return false;
      if (_filter == 'completed' && med.isActive) return false;

      // Search query
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = med.name.toLowerCase().contains(query);
        final matchDoctor =
            med.doctorName?.toLowerCase().contains(query) ?? false;
        final matchInstructions =
            med.instructions?.toLowerCase().contains(query) ?? false;
        if (!matchName && !matchDoctor && !matchInstructions) return false;
      }

      return true;
    }).toList();
  }

  /// Active medicines count
  int get activeMedicinesCount => _medicines.where((m) => m.isActive).length;

  /// Medicines scheduled for today
  List<Medicine> get todayMedicines {
    final todayWeekday = DateTime.now().weekday;
    return _medicines
        .where((m) => m.isActive && m.isScheduledOnWeekday(todayWeekday))
        .toList();
  }

  /// Binds provider to the current user's SQLite stream
  void bindUser(String? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _medicineSubscription?.cancel();

    if (userId == null) {
      _medicines = [];
      _notificationService.cancelAllNotifications();
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _medicineSubscription = _databaseService
        .medicinesStream(userId)
        .listen(
          (medicines) {
            _medicines = medicines;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();

            // Reschedule device notifications based on updated medicines
            _notificationService.rescheduleAll(medicines);
          },
          onError: (e) {
            _isLoading = false;
            _errorMessage = 'Failed to load medicines: $e';
            notifyListeners();
          },
        );
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  /// Add a new medicine
  Future<bool> addMedicine(Medicine medicine) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final docId = await _databaseService.addMedicine(medicine);
      final savedMed = medicine.copyWith(id: docId);
      // Schedule reminder alarms on device
      await _notificationService.scheduleMedicineReminder(savedMed);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to add medicine: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update an existing medicine schedule
  Future<bool> updateMedicine(Medicine medicine) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _databaseService.updateMedicine(medicine);
      // Cancel old alarms and reschedule updated alarms
      await _notificationService.cancelMedicineReminders(
        medicine.id,
        medicine.reminderTimes.length,
      );
      if (medicine.isActive) {
        await _notificationService.scheduleMedicineReminder(medicine);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update medicine: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete a medicine schedule
  Future<bool> deleteMedicine(String medicineId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final med = _medicines.firstWhere((m) => m.id == medicineId);
      await _databaseService.deleteMedicine(_currentUserId!, medicineId);
      // Cancel device alarms
      await _notificationService.cancelMedicineReminders(
        medicineId,
        med.reminderTimes.length,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete medicine: $e';
      notifyListeners();
      return false;
    }
  }

  /// Toggle medicine active/inactive status
  Future<bool> toggleActiveStatus(Medicine medicine) async {
    final updated = medicine.copyWith(
      isActive: !medicine.isActive,
      updatedAt: DateTime.now(),
    );
    return await updateMedicine(updated);
  }

  void clear() {
    _medicineSubscription?.cancel();
    _currentUserId = null;
    _medicines = [];
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _medicineSubscription?.cancel();
    super.dispose();
  }
}
