import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_user.dart';
import 'database_service.dart';

/// Local authentication service encapsulating SQLite credential management
/// and device session persistence.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService({DatabaseService? databaseService}) {
    if (databaseService != null) {
      _instance._dbService = databaseService;
    }
    return _instance;
  }
  AuthService._internal() {
    _initSession();
  }

  DatabaseService _dbService = DatabaseService();
  static const String _keyActiveUserId = 'active_user_id';

  LocalUser? _currentUser;
  final StreamController<LocalUser?> _authController =
      StreamController<LocalUser?>.broadcast();

  bool _isInitialized = false;

  /// Current signed-in local user
  LocalUser? get currentUser => _currentUser;

  /// Authentication state stream
  Stream<LocalUser?> get authStateChanges => _authController.stream;

  /// Check active user session on app launch
  Future<void> _initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getString(_keyActiveUserId);
      if (savedUid != null && savedUid.isNotEmpty) {
        final user = await _dbService.getUserById(savedUid);
        if (user != null) {
          _currentUser = user;
          _authController.add(_currentUser);
          debugPrint('[AuthService] Restored active session for user: ${user.email}');
          _isInitialized = true;
          return;
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Session check error: $e');
    }
    _currentUser = null;
    _authController.add(null);
    _isInitialized = true;
  }

  /// Wait until session initialization completes
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await _initSession();
  }

  /// Sign in with Email and Password
  Future<LocalUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dbService.authenticateUser(
        email: email.trim(),
        password: password,
      );

      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyActiveUserId, user.uid);

      _authController.add(_currentUser);
      return user;
    } catch (e) {
      debugPrint('[AuthService] Sign-in error: $e');
      rethrow;
    }
  }

  /// Register new user with Email, Password, and Display Name
  Future<LocalUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final user = await _dbService.registerUser(
        email: email.trim(),
        password: password,
        displayName: displayName.trim(),
      );

      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyActiveUserId, user.uid);

      _authController.add(_currentUser);
      return user;
    } catch (e) {
      debugPrint('[AuthService] Registration error: $e');
      rethrow;
    }
  }

  /// Reset password for an email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // In local mode, generate a temporary default or allow resetting
      await _dbService.resetPassword(
        email: email.trim(),
        newPassword: 'Password123',
      );
    } catch (e) {
      throw 'User with email $email was not found.';
    }
  }

  /// Update display name
  Future<void> updateDisplayName(String newName) async {
    if (_currentUser != null) {
      await _dbService.updateDisplayName(_currentUser!.uid, newName.trim());
      _currentUser = _currentUser!.copyWith(displayName: newName.trim());
      _authController.add(_currentUser);
    }
  }

  /// Sign out current user and clear device session
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyActiveUserId);
    } catch (e) {
      debugPrint('[AuthService] Sign-out preferences cleanup error: $e');
    }
    _currentUser = null;
    _authController.add(null);
  }

  /// Delete user account permanently from SQLite
  Future<void> deleteAccount() async {
    final user = _currentUser;
    if (user == null) throw 'No user is currently signed in.';

    try {
      await _dbService.deleteAllUserData(user.uid);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyActiveUserId);
      _currentUser = null;
      _authController.add(null);
    } catch (e) {
      throw 'Failed to delete account: $e';
    }
  }
}
