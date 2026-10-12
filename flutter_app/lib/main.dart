import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/services/firebase_service.dart';
import 'core/services/local_notification_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Immediately launch UI so web/mobile screen never stays blank
  runApp(
    const ProviderScope(
      child: StorePulseApp(),
    ),
  );

  // 2. Initialize local notification plugins asynchronously
  try {
    await LocalNotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Local notifications initialization note: $e');
  }

  // 3. Initialize Firebase asynchronously
  try {
    await FirebaseService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }
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
