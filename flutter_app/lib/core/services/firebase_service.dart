import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../firebase_options.dart';
import 'local_notification_service.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _isFirebaseInitialized = false;
  String? _fcmToken;
  String? _apnsToken;
  NotificationSettings? _notificationSettings;
  String? _deviceId;

  bool get isFirebaseInitialized => _isFirebaseInitialized;
  String? get fcmToken => _fcmToken;
  String? get apnsToken => _apnsToken;
  NotificationSettings? get notificationSettings => _notificationSettings;
  String get deviceId => _deviceId ?? 'unknown_device';

  bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> initialize() async {
    try {
      // 1. Get or generate persistent device ID
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString('storepulse_device_id');
      if (_deviceId == null) {
        _deviceId = const Uuid().v4();
        await prefs.setString('storepulse_device_id', _deviceId!);
      }

      // 2. Initialize Firebase with project credentials
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _isFirebaseInitialized = true;
      } catch (e) {
        debugPrint(
            'Firebase.initializeApp() note: Running in local diagnostic mode ($e)');
        _isFirebaseInitialized = false;
      }

      if (_isFirebaseInitialized) {
        await _setupMessaging();
      }
    } catch (e) {
      debugPrint('FirebaseService init error: $e');
    }
  }

  Future<void> _setupMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request push permissions
      try {
        _notificationSettings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
      } catch (e) {
        debugPrint('Push permission request note: $e');
      }

      // On physical iOS, request APNs token
      if (isIOS) {
        try {
          _apnsToken = await messaging.getAPNSToken();
        } catch (e) {
          debugPrint('APNs token note: $e');
        }
      }

      // Get FCM token
      try {
        _fcmToken = await messaging.getToken();
        debugPrint('Firebase Messaging FCM Token: $_fcmToken');
      } catch (e) {
        debugPrint('FCM Token note (Mock mode active): $e');
      }

      // Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        registerDeviceWithFirestore();
      });

      // Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground: ${message.messageId}');

        final title = message.notification?.title ?? message.data['title'] ?? 'StorePulse';
        final body = message.notification?.body ?? message.data['body'] ?? 'New simulated activity';

        LocalNotificationService.instance.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          payload: message.data.toString(),
        );

        _recordDeliveryConfirmation(message);
      });

      // Handle notification opened app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification clicked / opened: ${message.data}');
      });

      // Register device in Firestore
      await registerDeviceWithFirestore();
    } catch (e) {
      debugPrint('Messaging setup error: $e');
    }
  }

  Future<void> registerDeviceWithFirestore() async {
    if (!_isFirebaseInitialized || _deviceId == null) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final isGranted = _notificationSettings?.authorizationStatus ==
          AuthorizationStatus.authorized;

      String platformName = 'web';
      String deviceModel = 'Web Browser (Safari)';

      if (!kIsWeb) {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          platformName = 'ios';
          deviceModel = 'iPhone 18 Pro';
        } else if (defaultTargetPlatform == TargetPlatform.android) {
          platformName = 'android';
          deviceModel = 'Android Device';
        } else {
          platformName = 'windows';
          deviceModel = 'Windows Host';
        }
      }

      await firestore.collection('devices').doc(_deviceId).set({
        'deviceId': _deviceId,
        'fcmToken': _fcmToken,
        'apnsToken': _apnsToken,
        'platform': platformName,
        'deviceModel': deviceModel,
        'isPermissionGranted': isGranted,
        'isValid': true,
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Device registered in Firestore: $_deviceId');
    } catch (e) {
      debugPrint('Failed to register device in Firestore: $e');
    }
  }

  Future<void> _recordDeliveryConfirmation(RemoteMessage message) async {
    final historyId = message.data['historyId'] ?? message.messageId;
    if (historyId == null || !_isFirebaseInitialized) return;

    try {
      await FirebaseFirestore.instance.collection('history').doc(historyId).update({
        'status': 'delivered',
        'confirmedDeliveredAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to mark delivery confirmation in history: $e');
    }
  }

  Map<String, dynamic> getDiagnostics() {
    return {
      'isFirebaseInitialized': _isFirebaseInitialized,
      'deviceId': _deviceId,
      'hasFcmToken': _fcmToken != null,
      'fcmTokenPreview': _fcmToken != null
          ? '${_fcmToken!.substring(0, 12)}...${_fcmToken!.substring(_fcmToken!.length - 8)}'
          : 'None',
      'hasApnsToken': _apnsToken != null,
      'apnsToken': _apnsToken ?? 'Not Available (Requires iOS Physical Device & APNs Key)',
      'permissionStatus': _notificationSettings?.authorizationStatus.name ??
          'Not Requested / Unknown',
      'freeAppleAccountLimitation':
          'Free Apple Accounts cannot generate APNs Auth Keys (.p8) or enable the Push Notifications capability in Xcode.',
    };
  }
}
