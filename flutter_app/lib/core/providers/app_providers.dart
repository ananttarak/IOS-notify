import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/schedule_model.dart';
import '../models/template_model.dart';
import '../models/notification_history_model.dart';
import '../services/firebase_service.dart';
import '../services/local_notification_service.dart';

// --- SEED TEMPLATES (Single exact template matching reference screenshot) ---
final List<TemplateModel> _initialTemplates = [
  TemplateModel(
    id: 'tmpl_folkthreads',
    title: 'Order #{{order_id}}',
    body: '{{amount}}, {{items}} from {{channel}} •\n{{store}}',
    weight: 100,
    isEnabled: true,
    isSimulated: false,
    customAmount: '₹6,555.00',
    startOrderNumber: 1794,
    storeName: 'Folkthreads',
    defaultVariables: {
      'channel': 'Online Store',
      'store': 'Folkthreads',
      'amount': '₹6,555.00',
      'items': '1 item',
    },
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

// --- TEMPLATES NOTIFIER (Riverpod 3 Notifier) ---
class TemplatesNotifier extends Notifier<List<TemplateModel>> {
  @override
  List<TemplateModel> build() {
    return _initialTemplates;
  }

  void updateCustomAmount(String amount) {
    state = [
      for (final tmpl in state)
        tmpl.copyWith(
          customAmount: amount,
          defaultVariables: {
            ...tmpl.defaultVariables,
            'amount': amount,
          },
        ),
    ];
  }

  void updateStartOrderNumber(int startNum) {
    TemplateModel.setNextOrderNumber(startNum);
    state = [
      for (final tmpl in state)
        tmpl.copyWith(startOrderNumber: startNum),
    ];
  }

  void updateStoreName(String store) {
    state = [
      for (final tmpl in state)
        tmpl.copyWith(
          storeName: store,
          defaultVariables: {
            ...tmpl.defaultVariables,
            'store': store,
          },
        ),
    ];
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
    if (enabled.isEmpty) return _initialTemplates.first;
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
      final intervalMs = state.calculatedIntervalMs;
      final nextTime = DateTime.now().add(Duration(milliseconds: intervalMs));
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
    // Fire the first notification immediately for instant feedback
    ref.read(historyProvider.notifier).triggerScheduledPush();
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
    int? notificationsPerInterval,
    int? intervalMinutes,
    double? minOrderAmount,
    double? maxOrderAmount,
    double? orderAmount,
    int? startOrderNumber,
    String? storeName,
    int? minIntervalSeconds,
    int? maxIntervalSeconds,
    int? maxPerHour,
    int? maxPerDay,
    String? timezone,
    String? quietHoursStart,
    String? quietHoursEnd,
    int? duplicatePreventionMinutes,
  }) {
    if (startOrderNumber != null) {
      TemplateModel.setNextOrderNumber(startOrderNumber);
    }
    state = state.copyWith(
      notificationsPerInterval: notificationsPerInterval,
      intervalMinutes: intervalMinutes,
      minOrderAmount: minOrderAmount,
      maxOrderAmount: maxOrderAmount,
      orderAmount: orderAmount,
      startOrderNumber: startOrderNumber,
      storeName: storeName,
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
      _startClientPreviewLoop();
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

  /// Client-side simulation loop running based on 3 sliders (notifications count / interval minutes)
  void _startClientPreviewLoop() {
    _localLoopTimer?.cancel();
    if (state.status != SchedulerStatus.running || state.emergencyStop) return;

    final intervalMs = state.calculatedIntervalMs;
    _localLoopTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) async {
      if (state.status == SchedulerStatus.running && !state.emergencyStop) {
        await ref.read(historyProvider.notifier).triggerScheduledPush();
      } else {
        _localLoopTimer?.cancel();
        _localLoopTimer = null;
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
        ref.read(templatesProvider.notifier).selectRandomTemplate() ??
            _initialTemplates.first;

    final formattedAmount = schedule.getRandomFormattedAmount();
    final rendered = template.render({
      'amount': formattedAmount,
      'store': schedule.storeName,
    });
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
      fcmMessageId: 'shopify_push_$historyId',
      scheduledAt: DateTime.now(),
      fcmSubmittedAt: DateTime.now(),
      serverResponse: 'HTTP 200 - Order notification triggered',
      diagnostics: {
        'store': schedule.storeName,
        'amount': formattedAmount,
      },
      isSimulated: false,
    );

    state = [historyItem, ...state];
    ref.read(scheduleProvider.notifier).incrementCounts();
  }

  Future<void> sendTestNotification() async {
    final schedule = ref.read(scheduleProvider);
    final template =
        ref.read(templatesProvider.notifier).selectRandomTemplate() ??
            _initialTemplates.first;
    final formattedAmount = schedule.getRandomFormattedAmount();
    final rendered = template.render({
      'amount': formattedAmount,
      'store': schedule.storeName,
    });
    final historyId = const Uuid().v4();

    await LocalNotificationService.instance.showNotification(
      id: Random().nextInt(100000),
      title: rendered['title']!,
      body: rendered['body']!,
    );

    final item = NotificationHistoryModel(
      id: historyId,
      templateId: template.id,
      title: rendered['title']!,
      body: rendered['body']!,
      status: DeliveryStatus.submitted,
      fcmMessageId: 'shopify_push_$historyId',
      scheduledAt: DateTime.now(),
      fcmSubmittedAt: DateTime.now(),
      serverResponse: 'HTTP 200 - Order notification triggered',
      diagnostics: {'store': schedule.storeName, 'amount': formattedAmount},
      isSimulated: false,
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
