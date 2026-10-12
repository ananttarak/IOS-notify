import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/services/firebase_service.dart';
import 'core/services/local_notification_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local notifications (offline preview, in-app alerts)
  await LocalNotificationService.instance.initialize();

  // Initialize Firebase (or graceful fallback if credentials pending)
  await FirebaseService.instance.initialize();

  runApp(
    const ProviderScope(
      child: StorePulseApp(),
    ),
  );
}

class StorePulseApp extends StatelessWidget {
  const StorePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StorePulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
