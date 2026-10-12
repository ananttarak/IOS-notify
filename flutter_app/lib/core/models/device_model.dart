class DeviceModel {
  final String deviceId;
  final String? fcmToken;
  final String? apnsToken;
  final String platform;
  final String deviceModel;
  final String osVersion;
  final bool isPermissionGranted;
  final bool isValid;
  final DateTime lastSeenAt;

  const DeviceModel({
    required this.deviceId,
    this.fcmToken,
    this.apnsToken,
    this.platform = 'ios',
    this.deviceModel = 'iPhone 18 Pro',
    this.osVersion = 'iOS 18.0',
    this.isPermissionGranted = false,
    this.isValid = true,
    required this.lastSeenAt,
  });

  DeviceModel copyWith({
    String? deviceId,
    String? fcmToken,
    String? apnsToken,
    String? platform,
    String? deviceModel,
    String? osVersion,
    bool? isPermissionGranted,
    bool? isValid,
    DateTime? lastSeenAt,
  }) {
    return DeviceModel(
      deviceId: deviceId ?? this.deviceId,
      fcmToken: fcmToken ?? this.fcmToken,
      apnsToken: apnsToken ?? this.apnsToken,
      platform: platform ?? this.platform,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      isValid: isValid ?? this.isValid,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'fcmToken': fcmToken,
      'apnsToken': apnsToken,
      'platform': platform,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'isPermissionGranted': isPermissionGranted,
      'isValid': isValid,
      'lastSeenAt': lastSeenAt.toIso8601String(),
    };
  }

  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    return DeviceModel(
      deviceId: map['deviceId'] ?? '',
      fcmToken: map['fcmToken'],
      apnsToken: map['apnsToken'],
      platform: map['platform'] ?? 'ios',
      deviceModel: map['deviceModel'] ?? 'iPhone',
      osVersion: map['osVersion'] ?? '',
      isPermissionGranted: map['isPermissionGranted'] ?? false,
      isValid: map['isValid'] ?? true,
      lastSeenAt: map['lastSeenAt'] != null
          ? DateTime.tryParse(map['lastSeenAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
