import 'dart:async';

import 'package:flutter/material.dart';

import '../models/local_user.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  authenticating,
}

/// Provider managing local authentication state, profile synchronization, and credentials.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final DatabaseService _dbService;

  AuthStatus _status = AuthStatus.uninitialized;
  LocalUser? _user;
  UserProfile? _userProfile;
  String? _errorMessage;
  bool _isLoading = false;
  StreamSubscription<LocalUser?>? _authSubscription;

  AuthProvider({AuthService? authService, DatabaseService? databaseService})
    : _authService = authService ?? AuthService(),
      _dbService = databaseService ?? DatabaseService() {
    _init();
  }

  AuthStatus get status => _status;
  LocalUser? get user => _user;
  UserProfile? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;

  void _init() {
    // Eagerly check current user if already restored by AuthService
    if (_authService.currentUser != null) {
      _user = _authService.currentUser;
      _status = AuthStatus.authenticated;
      _syncUserProfile(_user!);
    }

    _authSubscription = _authService.authStateChanges.listen((
      LocalUser? localUser,
    ) async {
      _user = localUser;
      if (localUser != null) {
        _status = AuthStatus.authenticated;
        await _syncUserProfile(localUser);
      } else {
        _status = AuthStatus.unauthenticated;
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  /// Syncs user profile in local SQLite database.
  Future<void> _syncUserProfile(LocalUser localUser) async {
    try {
      final existingProfile = await _dbService.getUserProfile(localUser.uid);

      if (existingProfile != null) {
        _userProfile = existingProfile.copyWith(
          lastLoginAt: DateTime.now(),
          displayName: existingProfile.displayName.isNotEmpty
              ? existingProfile.displayName
              : localUser.displayName,
          photoUrl: localUser.photoURL ?? existingProfile.photoUrl,
        );
        await _dbService.saveUserProfile(_userProfile!);
      } else {
        final now = DateTime.now();
        _userProfile = UserProfile(
          userId: localUser.uid,
          email: localUser.email,
          displayName: localUser.displayName.isNotEmpty
              ? localUser.displayName
              : (localUser.email.split('@').first),
          photoUrl: localUser.photoURL,
          createdAt: now,
          lastLoginAt: now,
        );
        await _dbService.saveUserProfile(_userProfile!);
      }
    } catch (e) {
      debugPrint('[AuthProvider] User profile sync notice: $e');
      _userProfile = UserProfile(
        userId: localUser.uid,
        email: localUser.email,
        displayName: localUser.displayName,
        photoUrl: localUser.photoURL,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Register with email, password, and display name
  Future<bool> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Password reset request
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Update display name
  Future<bool> updateDisplayName(String newName) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.updateDisplayName(newName);
      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(displayName: newName);
        await _dbService.saveUserProfile(_userProfile!);
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Sign out current user and clear in-memory state
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _user = null;
      _userProfile = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Permanently delete account and all local data
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.deleteAccount();
      _user = null;
      _userProfile = null;
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
