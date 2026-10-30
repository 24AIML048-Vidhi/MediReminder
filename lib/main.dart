import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/dose_log_provider.dart';
import 'providers/health_provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite Database
  try {
    await DatabaseService().init();
    debugPrint('[Main] SQLite database initialized successfully.');
  } catch (e) {
    debugPrint('[Main] SQLite database initialization error: $e');
  }

  // Restore Local Authentication Session
  try {
    await AuthService().ensureInitialized();
  } catch (e) {
    debugPrint('[Main] Auth session restore notice: $e');
  }

  // Initialize Local Notifications and Timezone
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('[Main] Notification service initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => DoseLogProvider()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
      ],
      child: const MediReminderApp(),
    ),
  );
}

class MediReminderApp extends StatelessWidget {
  const MediReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'MediReminder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
