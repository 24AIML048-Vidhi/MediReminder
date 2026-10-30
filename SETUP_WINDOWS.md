# Windows Quick Start (Flutter + SQLite + Local Auth)

MediReminder now operates with **local SQLite persistence** and **local authentication**. No Firebase, Google Sign-In, or OAuth setup is required!

1. Open PowerShell and navigate to the project root:

   ```powershell
   cd path\to\medi_reminder
   flutter pub get
   ```

2. Run the application directly:

   ```powershell
   flutter run
   ```

3. Run quality checks & unit tests:

   ```powershell
   flutter analyze
   flutter test
   ```

4. Build release or debug APK:

   ```powershell
   flutter build apk --debug
   ```

### Architecture Notes
- **Database**: Relational SQLite database (`medi_reminder.db`) via `sqflite` and `sqflite_common_ffi`.
- **Authentication**: Local salted SHA-256 password hashing with active session persistence via `SharedPreferences`.
- **User Data Isolation**: User profiles, medicines, dose logs, and vital health metrics are keyed by `userId` in SQLite with cascading deletes.
- **Offline First**: All operations (scheduling, dose tracking, vitals history, and local notifications) function completely offline without cloud dependencies.
