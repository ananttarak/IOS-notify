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
  final DateTime? nextPlannedSendTime;
  final DateTime? lastSentTime;
  final int todayCount;
  final int currentHourCount;

  const ScheduleModel({
    this.status = SchedulerStatus.stopped,
    this.minIntervalSeconds = 30,
    this.maxIntervalSeconds = 180,
    this.maxPerHour = 20,
    this.maxPerDay = 100,
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

  ScheduleModel copyWith({
    SchedulerStatus? status,
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
      minIntervalSeconds: (map['minIntervalSeconds'] as num?)?.toInt() ?? 30,
      maxIntervalSeconds: (map['maxIntervalSeconds'] as num?)?.toInt() ?? 180,
      maxPerHour: (map['maxPerHour'] as num?)?.toInt() ?? 20,
      maxPerDay: (map['maxPerDay'] as num?)?.toInt() ?? 100,
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
