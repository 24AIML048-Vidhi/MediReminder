# MediReminder – Smart Medicine & Health Reminder

MediReminder is a Flutter mobile application for managing medication schedules, recording dose actions, tracking vital health indicators, and viewing adherence history. It uses **SQLite** for relational local data persistence, **Local Authentication** with salted SHA-256 password hashing, and local device notifications for medicine reminders.

No external Firebase project, Google Cloud Console, or OAuth setup is required. All data is saved on the user's device and remains immediately available across sessions.

---

## Key Features

- **Local Authentication**: User registration and sign-in with email and password, backed by salted SHA-256 password hashing and persistent device sessions.
- **Medicine Management**: Add, edit, search, filter, and delete medications with customized dosage, frequency, and multiple daily reminder times.
- **Medicine Reminders & Notifications**: Exact scheduled alarms with timezone awareness (`flutter_local_notifications`).
- **Daily Schedules & Dose History**: Mark doses as taken, skipped, or missed; compute today's adherence rate and 7-day adherence trends.
- **Health Tracking**: Monitor blood pressure, blood glucose, body weight, and body temperature with clinical range alerts.
- **Persistent Local Data**: SQLite relational database (`sqflite` & `sqflite_common_ffi`) isolating data per user with foreign-key cascades.
- **Cross-Platform Support**: Works seamlessly on Android, iOS, and Windows desktop.

---

## Quick Start

1. Open PowerShell / Terminal in the project root:

   ```bash
   flutter pub get
   ```

2. Run the application directly:

   ```bash
   flutter run
   ```

3. Run quality checks and tests:

   ```bash
   flutter analyze
   flutter test
   ```

---

## Architecture Overview

- **`lib/services/database_service.dart`**: SQLite schema creation and CRUD operations with reactive stream controllers for real-time UI updates.
- **`lib/services/auth_service.dart`**: Local authentication service, session management with `SharedPreferences`, and credential hashing.
- **`lib/services/notification_service.dart`**: Local notification scheduling, Android notification channel, and timezone initialization.
- **`lib/providers/`**: State management using Provider (`AuthProvider`, `MedicineProvider`, `DoseLogProvider`, `HealthProvider`, `ThemeProvider`).
- **`lib/models/`**: Data models (`Medicine`, `DoseLog`, `HealthRecord`, `LocalUser`, `UserProfile`, `UserSettings`).
