import 'dart:async';

import 'package:flutter/material.dart';

import '../models/health_record.dart';
import '../services/database_service.dart';

/// Provider managing health metric entries, history trends, and unusual readings.
class HealthProvider extends ChangeNotifier {
  final DatabaseService _databaseService;

  List<HealthRecord> _records = [];
  String _selectedMetric =
      'all'; // 'all', 'bp', 'glucose', 'weight', 'temperature'
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<HealthRecord>>? _healthSubscription;
  String? _currentUserId;

  HealthProvider({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService();

  List<HealthRecord> get allRecords => _records;
  String get selectedMetric => _selectedMetric;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<HealthRecord> get filteredRecords {
    if (_selectedMetric == 'all') return _records;
    return _records.where((rec) {
      switch (_selectedMetric) {
        case 'bp':
          return rec.systolicBp != null || rec.diastolicBp != null;
        case 'glucose':
          return rec.bloodGlucose != null;
        case 'weight':
          return rec.weightKg != null;
        case 'temperature':
          return rec.temperatureC != null;
        default:
          return true;
      }
    }).toList();
  }

  /// Latest health record recorded
  HealthRecord? get latestRecord => _records.isNotEmpty ? _records.first : null;

  /// Count of readings flagging unusual clinical values
  int get unusualReadingsCount =>
      _records.where((rec) => rec.hasUnusualReading).length;

  void setSelectedMetric(String metric) {
    _selectedMetric = metric;
    notifyListeners();
  }

  void bindUser(String? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    _healthSubscription?.cancel();

    if (userId == null) {
      _records = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _healthSubscription = _databaseService
        .healthRecordsStream(userId)
        .listen(
          (records) {
            _records = records;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (e) {
            _isLoading = false;
            _errorMessage = 'Failed to load health records: $e';
            notifyListeners();
          },
        );
  }

  Future<bool> addHealthRecord(HealthRecord record) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _databaseService.addHealthRecord(record);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to record health vitals: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateHealthRecord(HealthRecord record) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _databaseService.updateHealthRecord(record);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update health record: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteHealthRecord(String recordId) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _databaseService.deleteHealthRecord(_currentUserId!, recordId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete health record: $e';
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _healthSubscription?.cancel();
    _currentUserId = null;
    _records = [];
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _healthSubscription?.cancel();
    super.dispose();
  }
}
