import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../models/dose_log.dart';
import '../models/health_record.dart';
import '../models/local_user.dart';
import '../models/medicine.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';

/// Core SQLite Database Service for MediReminder.
/// Handles local authentication, user profiles, settings, medicines,
/// dose logs, and health records with reactive streams.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;
  static const String _dbName = 'medi_reminder.db';
  static const int _dbVersion = 1;

  final Map<String, StreamController<List<Medicine>>> _medicineControllers = {};
  final Map<String, StreamController<List<DoseLog>>> _doseLogControllers = {};
  final Map<String, StreamController<List<HealthRecord>>> _healthControllers =
      {};

  /// Initialize SQLite factory (for Windows / Linux desktop support)
  Future<void> init() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    await database;
  }

  /// Get or initialize active SQLite database
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        // Users table
        await db.execute('''
          CREATE TABLE users (
            userId TEXT PRIMARY KEY,
            email TEXT UNIQUE COLLATE NOCASE NOT NULL,
            passwordHash TEXT NOT NULL,
            salt TEXT NOT NULL,
            displayName TEXT NOT NULL,
            photoUrl TEXT,
            createdAt TEXT NOT NULL,
            lastLoginAt TEXT NOT NULL
          );
        ''');

        // User profiles table
        await db.execute('''
          CREATE TABLE user_profiles (
            userId TEXT PRIMARY KEY,
            email TEXT NOT NULL,
            displayName TEXT NOT NULL,
            photoUrl TEXT,
            createdAt TEXT NOT NULL,
            lastLoginAt TEXT NOT NULL,
            FOREIGN KEY (userId) REFERENCES users(userId) ON DELETE CASCADE
          );
        ''');

        // User settings table
        await db.execute('''
          CREATE TABLE user_settings (
            userId TEXT PRIMARY KEY,
            remindersEnabled INTEGER NOT NULL DEFAULT 1,
            soundEnabled INTEGER NOT NULL DEFAULT 1,
            vibrationEnabled INTEGER NOT NULL DEFAULT 1,
            themeMode TEXT NOT NULL DEFAULT 'system',
            dateFormat TEXT NOT NULL DEFAULT 'MMM dd, yyyy',
            FOREIGN KEY (userId) REFERENCES users(userId) ON DELETE CASCADE
          );
        ''');

        // Medicines table
        await db.execute('''
          CREATE TABLE medicines (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            name TEXT NOT NULL,
            dosageAmount REAL NOT NULL,
            dosageUnit TEXT NOT NULL,
            form TEXT NOT NULL,
            instructions TEXT,
            doctorName TEXT,
            startDate TEXT NOT NULL,
            endDate TEXT,
            isOngoing INTEGER NOT NULL DEFAULT 1,
            frequency TEXT NOT NULL,
            reminderTimes TEXT NOT NULL,
            selectedDays TEXT NOT NULL,
            notes TEXT,
            isActive INTEGER NOT NULL DEFAULT 1,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            FOREIGN KEY (userId) REFERENCES users(userId) ON DELETE CASCADE
          );
        ''');

        // Dose logs table
        await db.execute('''
          CREATE TABLE dose_logs (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            medicineId TEXT NOT NULL,
            medicineName TEXT NOT NULL,
            dosage TEXT NOT NULL,
            scheduledTime TEXT NOT NULL,
            actionTime TEXT,
            status TEXT NOT NULL,
            notes TEXT,
            createdAt TEXT NOT NULL,
            FOREIGN KEY (userId) REFERENCES users(userId) ON DELETE CASCADE
          );
        ''');

        // Health records table
        await db.execute('''
          CREATE TABLE health_records (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            dateTime TEXT NOT NULL,
            weightKg REAL,
            systolicBp INTEGER,
            diastolicBp INTEGER,
            bloodGlucose REAL,
            bloodGlucoseUnit TEXT NOT NULL,
            temperatureC REAL,
            notes TEXT,
            createdAt TEXT NOT NULL,
            FOREIGN KEY (userId) REFERENCES users(userId) ON DELETE CASCADE
          );
        ''');
      },
    );
  }

  // ==========================================
  // AUTHENTICATION & USERS
  // ==========================================

  /// Register a new user in local SQLite database
  Future<LocalUser> registerUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final db = await database;
    final cleanEmail = email.trim().toLowerCase();

    // Check if email already registered
    final existing = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [cleanEmail],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw 'An account already exists with this email address. Please sign in instead.';
    }

    final userId = const Uuid().v4();
    final salt = const Uuid().v4();
    final passwordHash = sha256.convert(utf8.encode('$salt:$password')).toString();
    final now = DateTime.now().toIso8601String();
    final cleanName = displayName.trim().isNotEmpty ? displayName.trim() : 'User';

    await db.insert('users', {
      'userId': userId,
      'email': cleanEmail,
      'passwordHash': passwordHash,
      'salt': salt,
      'displayName': cleanName,
      'photoUrl': null,
      'createdAt': now,
      'lastLoginAt': now,
    });

    final profile = UserProfile(
      userId: userId,
      email: cleanEmail,
      displayName: cleanName,
      photoUrl: null,
      createdAt: DateTime.parse(now),
      lastLoginAt: DateTime.parse(now),
    );
    await saveUserProfile(profile);

    final settings = UserSettings(userId: userId);
    await saveUserSettings(settings);

    return LocalUser(
      uid: userId,
      email: cleanEmail,
      displayName: cleanName,
      photoURL: null,
    );
  }

  /// Authenticate an existing user with email and password
  Future<LocalUser> authenticateUser({
    required String email,
    required String password,
  }) async {
    final db = await database;
    final cleanEmail = email.trim().toLowerCase();

    final result = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [cleanEmail],
      limit: 1,
    );

    if (result.isEmpty) {
      throw 'No user found with this email address. Please check your spelling or register.';
    }

    final row = result.first;
    final salt = row['salt'] as String;
    final storedHash = row['passwordHash'] as String;
    final computedHash = sha256.convert(utf8.encode('$salt:$password')).toString();

    if (computedHash != storedHash) {
      throw 'Incorrect password or credentials. Please try again or reset your password.';
    }

    final now = DateTime.now().toIso8601String();
    final userId = row['userId'] as String;

    await db.update(
      'users',
      {'lastLoginAt': now},
      where: 'userId = ?',
      whereArgs: [userId],
    );

    await db.update(
      'user_profiles',
      {'lastLoginAt': now},
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return LocalUser(
      uid: userId,
      email: row['email'] as String,
      displayName: row['displayName'] as String,
      photoURL: row['photoUrl'] as String?,
    );
  }

  /// Look up user by user ID
  Future<LocalUser?> getUserById(String userId) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    final row = result.first;
    return LocalUser(
      uid: row['userId'] as String,
      email: row['email'] as String,
      displayName: row['displayName'] as String,
      photoURL: row['photoUrl'] as String?,
    );
  }

  /// Reset password for a registered local email
  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final db = await database;
    final cleanEmail = email.trim().toLowerCase();

    final result = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [cleanEmail],
      limit: 1,
    );

    if (result.isEmpty) {
      throw 'No user found with this email address.';
    }

    final salt = const Uuid().v4();
    final passwordHash = sha256.convert(utf8.encode('$salt:$newPassword')).toString();

    await db.update(
      'users',
      {'passwordHash': passwordHash, 'salt': salt},
      where: 'LOWER(email) = ?',
      whereArgs: [cleanEmail],
    );
  }

  /// Update user display name in database
  Future<void> updateDisplayName(String userId, String newName) async {
    final db = await database;
    await db.update(
      'users',
      {'displayName': newName.trim()},
      where: 'userId = ?',
      whereArgs: [userId],
    );
    await db.update(
      'user_profiles',
      {'displayName': newName.trim()},
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // ==========================================
  // USER PROFILE & SETTINGS
  // ==========================================

  Future<UserProfile?> getUserProfile(String userId) async {
    final db = await database;
    final result = await db.query(
      'user_profiles',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return UserProfile.fromMap(result.first, userId);
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final db = await database;
    await db.insert(
      'user_profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.update(
      'users',
      {
        'displayName': profile.displayName,
        'photoUrl': profile.photoUrl,
        'lastLoginAt': profile.lastLoginAt.toIso8601String(),
      },
      where: 'userId = ?',
      whereArgs: [profile.userId],
    );
  }

  Future<UserSettings?> getUserSettings(String userId) async {
    final db = await database;
    final result = await db.query(
      'user_settings',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    final row = result.first;
    return UserSettings.fromMap(row, userId);
  }

  Future<void> saveUserSettings(UserSettings settings) async {
    final db = await database;
    final map = {
      'userId': settings.userId,
      'remindersEnabled': settings.remindersEnabled ? 1 : 0,
      'soundEnabled': settings.soundEnabled ? 1 : 0,
      'vibrationEnabled': settings.vibrationEnabled ? 1 : 0,
      'themeMode': settings.themeMode,
      'dateFormat': settings.dateFormat,
    };
    await db.insert(
      'user_settings',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==========================================
  // MEDICINES (CRUD & STREAMS)
  // ==========================================

  Stream<List<Medicine>> medicinesStream(String userId) {
    if (!_medicineControllers.containsKey(userId) ||
        _medicineControllers[userId]!.isClosed) {
      _medicineControllers[userId] =
          StreamController<List<Medicine>>.broadcast();
    }
    // Eagerly emit current data
    _notifyMedicines(userId);
    return _medicineControllers[userId]!.stream;
  }

  Future<void> _notifyMedicines(String userId) async {
    final controller = _medicineControllers[userId];
    if (controller == null || controller.isClosed) return;

    try {
      final list = await getMedicines(userId);
      if (!controller.isClosed) {
        controller.add(list);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  Future<List<Medicine>> getMedicines(String userId) async {
    final db = await database;
    final result = await db.query(
      'medicines',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return result
        .map((row) => Medicine.fromMap(row, row['id'] as String))
        .toList();
  }

  Map<String, dynamic> _medicineToDbMap(Medicine medicine, String id) {
    return {
      'id': id,
      'userId': medicine.userId,
      'name': medicine.name,
      'dosageAmount': medicine.dosageAmount,
      'dosageUnit': medicine.dosageUnit,
      'form': medicine.form,
      'instructions': medicine.instructions,
      'doctorName': medicine.doctorName,
      'startDate': medicine.startDate.toIso8601String(),
      'endDate': medicine.endDate?.toIso8601String(),
      'isOngoing': medicine.isOngoing ? 1 : 0,
      'frequency': medicine.frequency,
      'reminderTimes': jsonEncode(
        medicine.reminderTimes
            .map(
              (t) =>
                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
            )
            .toList(),
      ),
      'selectedDays': jsonEncode(medicine.selectedDays),
      'notes': medicine.notes,
      'isActive': medicine.isActive ? 1 : 0,
      'createdAt': medicine.createdAt.toIso8601String(),
      'updatedAt': medicine.updatedAt.toIso8601String(),
    };
  }

  Future<String> addMedicine(Medicine medicine) async {
    final db = await database;
    final id = medicine.id.isNotEmpty ? medicine.id : const Uuid().v4();
    final toInsert = _medicineToDbMap(medicine, id);

    await db.insert(
      'medicines',
      toInsert,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _notifyMedicines(medicine.userId);
    return id;
  }

  Future<void> updateMedicine(Medicine medicine) async {
    final db = await database;
    final toUpdate = _medicineToDbMap(medicine, medicine.id);

    await db.update(
      'medicines',
      toUpdate,
      where: 'id = ? AND userId = ?',
      whereArgs: [medicine.id, medicine.userId],
    );
    await _notifyMedicines(medicine.userId);
  }

  Future<void> deleteMedicine(String userId, String medicineId) async {
    final db = await database;
    await db.delete(
      'medicines',
      where: 'id = ? AND userId = ?',
      whereArgs: [medicineId, userId],
    );
    await _notifyMedicines(userId);
  }

  // ==========================================
  // DOSE LOGS (CRUD & STREAMS)
  // ==========================================

  Stream<List<DoseLog>> doseLogsStream(String userId) {
    if (!_doseLogControllers.containsKey(userId) ||
        _doseLogControllers[userId]!.isClosed) {
      _doseLogControllers[userId] =
          StreamController<List<DoseLog>>.broadcast();
    }
    _notifyDoseLogs(userId);
    return _doseLogControllers[userId]!.stream;
  }

  Future<void> _notifyDoseLogs(String userId) async {
    final controller = _doseLogControllers[userId];
    if (controller == null || controller.isClosed) return;

    try {
      final list = await getDoseLogs(userId);
      if (!controller.isClosed) {
        controller.add(list);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  Future<List<DoseLog>> getDoseLogs(String userId) async {
    final db = await database;
    final result = await db.query(
      'dose_logs',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'scheduledTime DESC',
    );

    return result
        .map((row) => DoseLog.fromMap(row, row['id'] as String))
        .toList();
  }

  Future<void> recordDoseLog(DoseLog log) async {
    final db = await database;
    await db.insert(
      'dose_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _notifyDoseLogs(log.userId);
  }

  Future<void> deleteDoseLog(String userId, String logId) async {
    final db = await database;
    await db.delete(
      'dose_logs',
      where: 'id = ? AND userId = ?',
      whereArgs: [logId, userId],
    );
    await _notifyDoseLogs(userId);
  }

  // ==========================================
  // HEALTH RECORDS (CRUD & STREAMS)
  // ==========================================

  Stream<List<HealthRecord>> healthRecordsStream(String userId) {
    if (!_healthControllers.containsKey(userId) ||
        _healthControllers[userId]!.isClosed) {
      _healthControllers[userId] =
          StreamController<List<HealthRecord>>.broadcast();
    }
    _notifyHealthRecords(userId);
    return _healthControllers[userId]!.stream;
  }

  Future<void> _notifyHealthRecords(String userId) async {
    final controller = _healthControllers[userId];
    if (controller == null || controller.isClosed) return;

    try {
      final list = await getHealthRecords(userId);
      if (!controller.isClosed) {
        controller.add(list);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  Future<List<HealthRecord>> getHealthRecords(String userId) async {
    final db = await database;
    final result = await db.query(
      'health_records',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dateTime DESC',
    );

    return result
        .map((row) => HealthRecord.fromMap(row, row['id'] as String))
        .toList();
  }

  Future<String> addHealthRecord(HealthRecord record) async {
    final db = await database;
    final id = record.id.isNotEmpty ? record.id : const Uuid().v4();
    final toInsert = record.copyWith(id: id).toMap();

    await db.insert(
      'health_records',
      toInsert,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _notifyHealthRecords(record.userId);
    return id;
  }

  Future<void> updateHealthRecord(HealthRecord record) async {
    final db = await database;
    await db.update(
      'health_records',
      record.toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [record.id, record.userId],
    );
    await _notifyHealthRecords(record.userId);
  }

  Future<void> deleteHealthRecord(String userId, String recordId) async {
    final db = await database;
    await db.delete(
      'health_records',
      where: 'id = ? AND userId = ?',
      whereArgs: [recordId, userId],
    );
    await _notifyHealthRecords(userId);
  }

  // ==========================================
  // ACCOUNT CLEANUP & DATA PURGE
  // ==========================================

  /// Permanently removes all records for the given user from SQLite database.
  Future<void> deleteAllUserData(String userId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('medicines', where: 'userId = ?', whereArgs: [userId]);
      await txn.delete('dose_logs', where: 'userId = ?', whereArgs: [userId]);
      await txn.delete('health_records', where: 'userId = ?', whereArgs: [userId]);
      await txn.delete('user_settings', where: 'userId = ?', whereArgs: [userId]);
      await txn.delete('user_profiles', where: 'userId = ?', whereArgs: [userId]);
      await txn.delete('users', where: 'userId = ?', whereArgs: [userId]);
    });

    _notifyMedicines(userId);
    _notifyDoseLogs(userId);
    _notifyHealthRecords(userId);
  }
}
