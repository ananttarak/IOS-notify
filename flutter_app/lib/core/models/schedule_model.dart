import 'dart:math';

enum SchedulerStatus {
  running,
  paused,
  stopped;

  String get label {
    switch (this) {
      case SchedulerStatus.running:
        return 'Active';
      case SchedulerStatus.paused:
        return 'Paused';
      case SchedulerStatus.stopped:
        return 'Stopped';
    }
  }
}

class ScheduleModel {
  final SchedulerStatus status;
  final int notificationsPerInterval; // Slider 1: Notifications count (e.g. 10)
  final int intervalMinutes;          // Slider 2: In how many minutes (e.g. 1 or 2 minutes)
  final double minOrderAmount;        // Slider 3: Start Amount (e.g. ₹2,000.00)
  final double maxOrderAmount;        // Slider 4: End Amount (e.g. ₹5,000.00)
  final double orderAmount;           // Legacy fallback
  final int startOrderNumber;         // Order sequence start (e.g. 1794, incrementing 1 by 1)
  final String storeName;             // Store name (e.g. "Folkthreads")
  final int minIntervalSeconds;
  final int maxIntervalSeconds;
  final int maxPerHour;
  final int maxPerDay;
  final List<int> allowedDays; // 1 = Monday, 7 = Sunday
  final String timezone;
  final String quietHoursStart; // "22:00"
  final String quietHoursEnd; // "07:00"
  final int duplicatePreventionMinutes;
  final bool emergencyStop;
  final int intervalMilliseconds;
  final DateTime? nextPlannedSendTime;
  final DateTime? lastSentTime;
  final int todayCount;
  final int currentHourCount;

  const ScheduleModel({
    this.status = SchedulerStatus.stopped,
    this.notificationsPerInterval = 10,
    this.intervalMinutes = 1,
    this.minOrderAmount = 2000.0,
    this.maxOrderAmount = 5000.0,
    this.orderAmount = 5000.0,
    this.startOrderNumber = 1794,
    this.storeName = 'Folkthreads',
    this.intervalMilliseconds = 40,
    this.minIntervalSeconds = 0,
    this.maxIntervalSeconds = 1,
    this.maxPerHour = 50000,
    this.maxPerDay = 500000,
    this.allowedDays = const [1, 2, 3, 4, 5, 6, 7],
    this.timezone = 'UTC',
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.duplicatePreventionMinutes = 5,
    this.emergencyStop = false,
    this.nextPlannedSendTime,
    this.lastSentTime,
    this.todayCount = 0,
    this.currentHourCount = 0,
  });

  /// Generates a realistic random amount between [minOrderAmount] and [maxOrderAmount]
  /// and formats it with Indian Rupee notation (e.g. ₹3,450.00)
  String getRandomFormattedAmount() {
    final lower = min(minOrderAmount, maxOrderAmount);
    final upper = max(minOrderAmount, maxOrderAmount);
    double val;
    if (lower == upper) {
      val = lower;
    } else {
      val = lower + Random().nextDouble() * (upper - lower);
    }
    // Round to nearest integer for clean realistic store pricing
    final rounded = val.roundToDouble();
    final parts = rounded.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final dec = parts[1];
    return '₹${_formatIndianRupee(whole)}.$dec';
  }

  static String _formatIndianRupee(String val) {
    if (val.length <= 3) return val;
    final last3 = val.substring(val.length - 3);
    final rest = val.substring(0, val.length - 3);
    final reg = RegExp(r'\B(?=(\d{2})+(?!\d))');
    return '${rest.replaceAll(reg, ',')},$last3';
  }

  /// Calculates interval delay in milliseconds based on:
  /// Slider 1: Notifications Count
  /// Slider 2: Interval Window in Minutes
  int get calculatedIntervalMs {
    final totalSeconds = intervalMinutes * 60;
    return (totalSeconds / max(1, notificationsPerInterval) * 1000).round().clamp(100, 600000);
  }

  double get calculatedIntervalSeconds {
    final totalSeconds = intervalMinutes * 60;
    return totalSeconds / max(1, notificationsPerInterval);
  }

  ScheduleModel copyWith({
    SchedulerStatus? status,
    int? notificationsPerInterval,
    int? intervalMinutes,
    double? minOrderAmount,
    double? maxOrderAmount,
    double? orderAmount,
    int? startOrderNumber,
    String? storeName,
    int? intervalMilliseconds,
    int? minIntervalSeconds,
    int? maxIntervalSeconds,
    int? maxPerHour,
    int? maxPerDay,
    List<int>? allowedDays,
    String? timezone,
    String? quietHoursStart,
    String? quietHoursEnd,
    int? duplicatePreventionMinutes,
    bool? emergencyStop,
    DateTime? nextPlannedSendTime,
    DateTime? lastSentTime,
    int? todayCount,
    int? currentHourCount,
  }) {
    return ScheduleModel(
      status: status ?? this.status,
      notificationsPerInterval:
          notificationsPerInterval ?? this.notificationsPerInterval,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxOrderAmount: maxOrderAmount ?? this.maxOrderAmount,
      orderAmount: orderAmount ?? this.orderAmount,
      startOrderNumber: startOrderNumber ?? this.startOrderNumber,
      storeName: storeName ?? this.storeName,
      intervalMilliseconds: intervalMilliseconds ?? this.intervalMilliseconds,
      minIntervalSeconds: minIntervalSeconds ?? this.minIntervalSeconds,
      maxIntervalSeconds: maxIntervalSeconds ?? this.maxIntervalSeconds,
      maxPerHour: maxPerHour ?? this.maxPerHour,
      maxPerDay: maxPerDay ?? this.maxPerDay,
      allowedDays: allowedDays ?? this.allowedDays,
      timezone: timezone ?? this.timezone,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      duplicatePreventionMinutes:
          duplicatePreventionMinutes ?? this.duplicatePreventionMinutes,
      emergencyStop: emergencyStop ?? this.emergencyStop,
      nextPlannedSendTime: nextPlannedSendTime ?? this.nextPlannedSendTime,
      lastSentTime: lastSentTime ?? this.lastSentTime,
      todayCount: todayCount ?? this.todayCount,
      currentHourCount: currentHourCount ?? this.currentHourCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'notificationsPerInterval': notificationsPerInterval,
      'intervalMinutes': intervalMinutes,
      'minOrderAmount': minOrderAmount,
      'maxOrderAmount': maxOrderAmount,
      'orderAmount': orderAmount,
      'startOrderNumber': startOrderNumber,
      'storeName': storeName,
      'intervalMilliseconds': intervalMilliseconds,
      'minIntervalSeconds': minIntervalSeconds,
      'maxIntervalSeconds': maxIntervalSeconds,
      'maxPerHour': maxPerHour,
      'maxPerDay': maxPerDay,
      'allowedDays': allowedDays,
      'timezone': timezone,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'duplicatePreventionMinutes': duplicatePreventionMinutes,
      'emergencyStop': emergencyStop,
      'nextPlannedSendTime': nextPlannedSendTime?.toIso8601String(),
      'lastSentTime': lastSentTime?.toIso8601String(),
      'todayCount': todayCount,
      'currentHourCount': currentHourCount,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    SchedulerStatus parsedStatus = SchedulerStatus.stopped;
    if (map['status'] == 'running') parsedStatus = SchedulerStatus.running;
    if (map['status'] == 'paused') parsedStatus = SchedulerStatus.paused;

    return ScheduleModel(
      status: parsedStatus,
      notificationsPerInterval:
          (map['notificationsPerInterval'] as num?)?.toInt() ?? 10,
      intervalMinutes: (map['intervalMinutes'] as num?)?.toInt() ?? 1,
      minOrderAmount: (map['minOrderAmount'] as num?)?.toDouble() ?? 2000.0,
      maxOrderAmount: (map['maxOrderAmount'] as num?)?.toDouble() ?? 5000.0,
      orderAmount: (map['orderAmount'] as num?)?.toDouble() ?? 5000.0,
      startOrderNumber: (map['startOrderNumber'] as num?)?.toInt() ?? 1794,
      storeName: map['storeName'] ?? 'Folkthreads',
      intervalMilliseconds:
          (map['intervalMilliseconds'] as num?)?.toInt() ?? 40,
      minIntervalSeconds: (map['minIntervalSeconds'] as num?)?.toInt() ?? 0,
      maxIntervalSeconds: (map['maxIntervalSeconds'] as num?)?.toInt() ?? 1,
      maxPerHour: (map['maxPerHour'] as num?)?.toInt() ?? 50000,
      maxPerDay: (map['maxPerDay'] as num?)?.toInt() ?? 500000,
      allowedDays: (map['allowedDays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
      timezone: map['timezone'] ?? 'UTC',
      quietHoursStart: map['quietHoursStart'] ?? '22:00',
      quietHoursEnd: map['quietHoursEnd'] ?? '07:00',
      duplicatePreventionMinutes:
          (map['duplicatePreventionMinutes'] as num?)?.toInt() ?? 5,
      emergencyStop: map['emergencyStop'] ?? false,
      nextPlannedSendTime: map['nextPlannedSendTime'] != null
          ? DateTime.tryParse(map['nextPlannedSendTime'])
          : null,
      lastSentTime: map['lastSentTime'] != null
          ? DateTime.tryParse(map['lastSentTime'])
          : null,
      todayCount: (map['todayCount'] as num?)?.toInt() ?? 0,
      currentHourCount: (map['currentHourCount'] as num?)?.toInt() ?? 0,
    );
  }
}
