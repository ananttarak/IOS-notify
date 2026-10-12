import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/schedule_model.dart';
import '../models/template_model.dart';
import '../models/notification_history_model.dart';
import '../services/firebase_service.dart';
import '../services/local_notification_service.dart';

// --- SEED TEMPLATES ---
final List<TemplateModel> _initialTemplates = [
  TemplateModel(
    id: 'tmpl_1',
    title: 'Order #{{order_id}}',
    body: '{{amount}}, {{items}} item(s) from Online Store · Paya Ecom',
    weight: 40,
    isEnabled: true,
    isSimulated: true,
    defaultVariables: {'store': 'Online Store · Paya Ecom'},
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TemplateModel(
    id: 'tmpl_2',
    title: 'Store Activity',
    body: 'Your store has a new activity update.',
    weight: 20,
    isEnabled: true,
    isSimulated: true,
    defaultVariables: {},
    createdAt: DateTime.now().subtract(const Duration(hours: 18)),
  ),
  TemplateModel(
    id: 'tmpl_3',
    title: 'New Order Received',
    body: 'Simulation: a new order notification preview.',
    weight: 25,
    isEnabled: true,
    isSimulated: true,
    defaultVariables: {},
    createdAt: DateTime.now().subtract(const Duration(hours: 12)),
  ),
  TemplateModel(
    id: 'tmpl_4',
    title: 'Sales Update',
    body: 'Your simulated store activity update is ready.',
    weight: 15,
    isEnabled: true,
    isSimulated: true,
    defaultVariables: {},
    createdAt: DateTime.now().subtract(const Duration(hours: 4)),
  ),
];

// --- TEMPLATES NOTIFIER (Riverpod 3 Notifier) ---
class TemplatesNotifier extends Notifier<List<TemplateModel>> {
  @override
  List<TemplateModel> build() {
    return _initialTemplates;
  }

  void addTemplate(TemplateModel template) {
    state = [template, ...state];
  }

  void updateTemplate(TemplateModel updated) {
    state = [
      for (final tmpl in state)
        if (tmpl.id == updated.id) updated else tmpl,
    ];
  }

  void deleteTemplate(String id) {
    state = state.where((tmpl) => tmpl.id != id).toList();
  }

  void toggleEnabled(String id) {
    state = [
      for (final tmpl in state)
        if (tmpl.id == id) tmpl.copyWith(isEnabled: !tmpl.isEnabled) else tmpl,
    ];
  }

  TemplateModel? selectRandomTemplate() {
    final enabled = state.where((t) => t.isEnabled).toList();
    if (enabled.isEmpty) return null;

    final totalWeight = enabled.fold<int>(0, (sum, t) => sum + t.weight);
    if (totalWeight <= 0) {
      return enabled[Random().nextInt(enabled.length)];
    }

    int randomValue = Random().nextInt(totalWeight);
    for (final tmpl in enabled) {
      if (randomValue < tmpl.weight) {
        return tmpl;
      }
      randomValue -= tmpl.weight;
    }
    return enabled.first;
  }
}

final templatesProvider =
    NotifierProvider<TemplatesNotifier, List<TemplateModel>>(
        TemplatesNotifier.new);

// --- SCHEDULE NOTIFIER (Riverpod 3 Notifier) ---
class ScheduleNotifier extends Notifier<ScheduleModel> {
  Timer? _localLoopTimer;

  @override
  ScheduleModel build() {
    ref.onDispose(() {
      _localLoopTimer?.cancel();
    });
    return const ScheduleModel();
  }

  void _calculateNextPlannedSend() {
    if (state.status == SchedulerStatus.running && !state.emergencyStop) {
      final range = max(1, state.maxIntervalSeconds - state.minIntervalSeconds);
      final delaySeconds = state.minIntervalSeconds + Random().nextInt(range);
      final nextTime = DateTime.now().add(Duration(seconds: delaySeconds));
      state = state.copyWith(nextPlannedSendTime: nextTime);
    } else {
      state = state.copyWith(nextPlannedSendTime: null);
    }
  }

  void start() {
    state = state.copyWith(
      status: SchedulerStatus.running,
      emergencyStop: false,
    );
    _calculateNextPlannedSend();
    _startClientPreviewLoop();
  }

  void pause() {
    state = state.copyWith(status: SchedulerStatus.paused);
    _localLoopTimer?.cancel();
    _localLoopTimer = null;
  }

  void resume() {
    state = state.copyWith(status: SchedulerStatus.running);
    _calculateNextPlannedSend();
    _startClientPreviewLoop();
  }

  void stop() {
    state = state.copyWith(
      status: SchedulerStatus.stopped,
      nextPlannedSendTime: null,
    );
    _localLoopTimer?.cancel();
    _localLoopTimer = null;
  }

  void toggleEmergencyStop() {
    final isStopped = !state.emergencyStop;
    state = state.copyWith(
      emergencyStop: isStopped,
      status: isStopped ? SchedulerStatus.stopped : SchedulerStatus.paused,
      nextPlannedSendTime: null,
    );
    if (isStopped) {
      _localLoopTimer?.cancel();
      _localLoopTimer = null;
    }
  }

  void updateSettings({
    int? minIntervalSeconds,
    int? maxIntervalSeconds,
    int? maxPerHour,
    int? maxPerDay,
    String? timezone,
    String? quietHoursStart,
    String? quietHoursEnd,
    int? duplicatePreventionMinutes,
  }) {
    state = state.copyWith(
      minIntervalSeconds: minIntervalSeconds,
      maxIntervalSeconds: maxIntervalSeconds,
      maxPerHour: maxPerHour,
      maxPerDay: maxPerDay,
      timezone: timezone,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      duplicatePreventionMinutes: duplicatePreventionMinutes,
    );
    if (state.status == SchedulerStatus.running) {
      _calculateNextPlannedSend();
    }
  }

  void incrementCounts() {
    state = state.copyWith(
      todayCount: state.todayCount + 1,
      currentHourCount: state.currentHourCount + 1,
      lastSentTime: DateTime.now(),
    );
    _calculateNextPlannedSend();
  }

  /// Client-side simulation loop for local previews when running on Windows/Web
  void _startClientPreviewLoop() {
    _localLoopTimer?.cancel();
    if (state.status != SchedulerStatus.running || state.emergencyStop) return;

    final next = state.nextPlannedSendTime;
    final now = DateTime.now();
    final delay = (next != null && next.isAfter(now))
        ? next.difference(now)
        : Duration(seconds: state.minIntervalSeconds);

    _localLoopTimer = Timer(delay, () async {
      if (state.status == SchedulerStatus.running && !state.emergencyStop) {
        await ref.read(historyProvider.notifier).triggerScheduledPush();
        _startClientPreviewLoop();
      }
    });
  }
}

final scheduleProvider =
    NotifierProvider<ScheduleNotifier, ScheduleModel>(ScheduleNotifier.new);

// --- NOTIFICATION HISTORY NOTIFIER (Riverpod 3 Notifier) ---
class HistoryNotifier extends Notifier<List<NotificationHistoryModel>> {
  @override
  List<NotificationHistoryModel> build() {
    return [];
  }

  Future<void> triggerScheduledPush() async {
    final schedule = ref.read(scheduleProvider);
    if (schedule.emergencyStop) return;

    // Check rate limit caps
    if (schedule.currentHourCount >= schedule.maxPerHour ||
        schedule.todayCount >= schedule.maxPerDay) {
      final skippedItem = NotificationHistoryModel(
        id: const Uuid().v4(),
        templateId: 'system_rate_limit',
        title: 'Rate Limit Threshold Reached',
        body:
            'Scheduled send bypassed: Hourly cap (${schedule.maxPerHour}) or Daily cap (${schedule.maxPerDay}) reached.',
        status: DeliveryStatus.skippedRateLimited,
        scheduledAt: DateTime.now(),
        serverResponse: 'HTTP 429 - Client / Server Rate Limiter',
        isSimulated: true,
      );
      state = [skippedItem, ...state];
      return;
    }

    final template =
        ref.read(templatesProvider.notifier).selectRandomTemplate();
    if (template == null) return;

    final rendered = template.render();
    final historyId = const Uuid().v4();

    // Trigger local banner for immediate sensory confirmation
    await LocalNotificationService.instance.showNotification(
      id: Random().nextInt(100000),
      title: rendered['title']!,
      body: rendered['body']!,
    );

    final historyItem = NotificationHistoryModel(
      id: historyId,
      templateId: template.id,
      title: rendered['title']!,
      body: rendered['body']!,
      status: DeliveryStatus.submitted,
      fcmMessageId: 'projects/storepulse/messages/fcm_$historyId',
      scheduledAt: DateTime.now(),
      fcmSubmittedAt: DateTime.now(),
      serverResponse: 'HTTP 200 - FCM Accepted for APNs Delivery',
      diagnostics: {
        'weight': template.weight,
        'channel': 'apns-priority-10',
        'isSimulated': true,
      },
      isSimulated: true,
    );

    state = [historyItem, ...state];
    ref.read(scheduleProvider.notifier).incrementCounts();
  }

  Future<void> sendTestNotification({
    String title = 'Order #6745',
    String body = '\$34.99, 1 item from Online Store · Paya Ecom',
  }) async {
    final historyId = const Uuid().v4();

    await LocalNotificationService.instance.showNotification(
      id: Random().nextInt(100000),
      title: title,
      body: body,
    );

    final item = NotificationHistoryModel(
      id: historyId,
      templateId: 'test_manual',
      title: title,
      body: body,
      status: DeliveryStatus.submitted,
      fcmMessageId: 'fcm_test_$historyId',
      scheduledAt: DateTime.now(),
      fcmSubmittedAt: DateTime.now(),
      serverResponse: 'HTTP 200 - Test Push Dispatched via FCM gateway',
      diagnostics: {'test': true, 'environment': 'sandbox/production'},
      isSimulated: true,
    );

    state = [item, ...state];
    ref.read(scheduleProvider.notifier).incrementCounts();
  }

  void clearHistory() {
    state = [];
  }
}

final historyProvider =
    NotifierProvider<HistoryNotifier, List<NotificationHistoryModel>>(
        HistoryNotifier.new);

// --- DIAGNOSTICS PROVIDER ---
final diagnosticsProvider = Provider<Map<String, dynamic>>((ref) {
  return FirebaseService.instance.getDiagnostics();
});
