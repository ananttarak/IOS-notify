import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';

class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnostics = ref.watch(diagnosticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device & APNs Diagnostics'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Apple Developer Account Warning Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.4)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.accentOrange, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Apple Free Account Push Blocker',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Free Apple Accounts (personal team sideloading via Xcode) do not support the Apple Push Notification service (APNs) capability. Apple restricts APNs keys (.p8) and push entitlements exclusively to paid Apple Developer Program memberships (\$99/year).\n\nWhile using a free account, the app operates in Full Local Simulator & In-App Push mode, allowing 100% of the UI, scheduling, rate limiting, and sound alerts to be tested directly on your iPhone.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'DIAGNOSTIC STATUS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _tile(
                    context,
                    title: 'Persistent Device ID',
                    value: diagnostics['deviceId'] ?? 'N/A',
                    isMono: true,
                    canCopy: true,
                  ),
                  const Divider(),
                  _tile(
                    context,
                    title: 'Firebase Core Initialized',
                    value: diagnostics['isFirebaseInitialized'] == true ? 'Yes' : 'No (Local Diagnostic Mode)',
                    valueColor: diagnostics['isFirebaseInitialized'] == true
                        ? AppTheme.accentGreen
                        : AppTheme.accentOrange,
                  ),
                  const Divider(),
                  _tile(
                    context,
                    title: 'FCM Token Present',
                    value: diagnostics['hasFcmToken'] == true ? 'Registered' : 'None (Mock Client)',
                    valueColor: diagnostics['hasFcmToken'] == true
                        ? AppTheme.accentGreen
                        : Colors.grey,
                  ),
                  const Divider(),
                  _tile(
                    context,
                    title: 'APNs Token Present',
                    value: diagnostics['hasApnsToken'] == true ? 'Registered' : 'None (Blocked by Free Account)',
                    valueColor: diagnostics['hasApnsToken'] == true
                        ? AppTheme.accentGreen
                        : Colors.grey,
                  ),
                  const Divider(),
                  _tile(
                    context,
                    title: 'Notification Permission',
                    value: diagnostics['permissionStatus'].toString(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'PREREQUISITES CHECKLIST FOR REMOTE APNS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _checkItem(true, '1. Unique Bundle Identifier (com.storepulse.notifications)'),
                  _checkItem(true, '2. Flutter iOS runner configured with Push capability schema'),
                  _checkItem(false, '3. Paid Apple Developer Program membership'),
                  _checkItem(false, '4. APNs Auth Key (.p8 file) generated on developer.apple.com'),
                  _checkItem(false, '5. APNs Key uploaded to Firebase Cloud Messaging console'),
                  _checkItem(false, '6. GoogleService-Info.plist added to ios/Runner/ directory'),
                  _checkItem(true, '7. Local notification preview engine active for Windows dev'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String title,
    required String value,
    Color? valueColor,
    bool isMono = false,
    bool canCopy = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: isMono ? 'monospace' : null,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
        if (canCopy)
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard!')),
              );
            },
          ),
      ],
    );
  }

  Widget _checkItem(bool isDone, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isDone ? AppTheme.accentGreen : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDone ? null : Colors.grey,
                fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
