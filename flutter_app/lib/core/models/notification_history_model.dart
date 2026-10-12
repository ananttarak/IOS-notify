enum DeliveryStatus {
  scheduled,
  submitted, // Accepted by FCM HTTP v1 gateway
  delivered, // Confirmed on physical device via foreground/background callback
  failed, // Rejected or error
  skippedRateLimited, // Skipped by hourly/daily cap
  skippedQuietHours; // Skipped due to quiet hours

  String get label {
    switch (this) {
      case DeliveryStatus.scheduled:
        return 'Scheduled';
      case DeliveryStatus.submitted:
        return 'FCM Accepted (In Transit)';
      case DeliveryStatus.delivered:
        return 'Confirmed Delivered';
      case DeliveryStatus.failed:
        return 'Delivery Failed';
      case DeliveryStatus.skippedRateLimited:
        return 'Rate Limit Exceeded';
      case DeliveryStatus.skippedQuietHours:
        return 'Quiet Hours Active';
    }
  }
}

class NotificationHistoryModel {
  final String id;
  final String templateId;
  final String title;
  final String body;
  final DeliveryStatus status;
  final String? fcmMessageId;
  final DateTime scheduledAt;
  final DateTime? fcmSubmittedAt;
  final DateTime? confirmedDeliveredAt;
  final String? serverResponse;
  final String? errorMessage;
  final Map<String, dynamic> diagnostics;
  final bool isSimulated;

  const NotificationHistoryModel({
    required this.id,
    required this.templateId,
    required this.title,
    required this.body,
    required this.status,
    this.fcmMessageId,
    required this.scheduledAt,
    this.fcmSubmittedAt,
    this.confirmedDeliveredAt,
    this.serverResponse,
    this.errorMessage,
    this.diagnostics = const {},
    this.isSimulated = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'templateId': templateId,
      'title': title,
      'body': body,
      'status': status.name,
      'fcmMessageId': fcmMessageId,
      'scheduledAt': scheduledAt.toIso8601String(),
      'fcmSubmittedAt': fcmSubmittedAt?.toIso8601String(),
      'confirmedDeliveredAt': confirmedDeliveredAt?.toIso8601String(),
      'serverResponse': serverResponse,
      'errorMessage': errorMessage,
      'diagnostics': diagnostics,
      'isSimulated': isSimulated,
    };
  }

  factory NotificationHistoryModel.fromMap(
      Map<String, dynamic> map, String docId) {
    DeliveryStatus parsedStatus = DeliveryStatus.scheduled;
    final statusStr = map['status'] as String?;
    if (statusStr != null) {
      for (final s in DeliveryStatus.values) {
        if (s.name == statusStr) {
          parsedStatus = s;
          break;
        }
      }
    }

    return NotificationHistoryModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? ''),
      templateId: map['templateId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      status: parsedStatus,
      fcmMessageId: map['fcmMessageId'],
      scheduledAt: map['scheduledAt'] != null
          ? DateTime.tryParse(map['scheduledAt']) ?? DateTime.now()
          : DateTime.now(),
      fcmSubmittedAt: map['fcmSubmittedAt'] != null
          ? DateTime.tryParse(map['fcmSubmittedAt'])
          : null,
      confirmedDeliveredAt: map['confirmedDeliveredAt'] != null
          ? DateTime.tryParse(map['confirmedDeliveredAt'])
          : null,
      serverResponse: map['serverResponse'],
      errorMessage: map['errorMessage'],
      diagnostics: Map<String, dynamic>.from(map['diagnostics'] ?? {}),
      isSimulated: map['isSimulated'] ?? true,
    );
  }
}
