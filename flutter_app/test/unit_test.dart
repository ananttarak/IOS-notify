import 'package:flutter_test/flutter_test.dart';
import 'package:storepulse/core/models/template_model.dart';
import 'package:storepulse/core/models/schedule_model.dart';
import 'package:storepulse/core/models/notification_history_model.dart';

void main() {
  group('TemplateModel Tests', () {
    test('renders variables correctly and preserves simulated flag', () {
      final template = TemplateModel(
        id: 'test_1',
        title: 'Order #{{order_id}}',
        body: '{{amount}}, {{items}} items from {{store}}',
        weight: 50,
        isEnabled: true,
        isSimulated: true,
        createdAt: DateTime.now(),
      );

      final rendered = template.render({
        'order_id': '9999',
        'amount': '\$49.99',
        'items': '2',
        'store': 'MyTestStore',
      });

      expect(rendered['title'], equals('Order #9999'));
      expect(rendered['body'], equals('\$49.99, 2 items from MyTestStore'));
      expect(rendered['isSimulated'], equals('true'));
    });

    test('serializes to map and deserializes correctly', () {
      final now = DateTime.now();
      final template = TemplateModel(
        id: 'test_2',
        title: 'Store Activity',
        body: 'Your store has a new update',
        weight: 30,
        isEnabled: false,
        isSimulated: true,
        createdAt: now,
      );

      final map = template.toMap();
      final revived = TemplateModel.fromMap(map, 'test_2');

      expect(revived.id, equals('test_2'));
      expect(revived.title, equals('Store Activity'));
      expect(revived.weight, equals(30));
      expect(revived.isEnabled, isFalse);
    });
  });

  group('ScheduleModel Tests', () {
    test('defaults to stopped status and default safety limits', () {
      const schedule = ScheduleModel();
      expect(schedule.status, equals(SchedulerStatus.stopped));
      expect(schedule.minIntervalSeconds, equals(30));
      expect(schedule.maxIntervalSeconds, equals(180));
      expect(schedule.maxPerHour, equals(20));
      expect(schedule.maxPerDay, equals(100));
      expect(schedule.emergencyStop, isFalse);
    });

    test('supports status transitions and copyWith', () {
      const schedule = ScheduleModel();
      final running = schedule.copyWith(status: SchedulerStatus.running);
      expect(running.status, equals(SchedulerStatus.running));

      final stopped = running.copyWith(emergencyStop: true);
      expect(stopped.emergencyStop, isTrue);
    });
  });

  group('NotificationHistoryModel Tests', () {
    test('status enum mapping and delivery diagnostics', () {
      final history = NotificationHistoryModel(
        id: 'hist_1',
        templateId: 'tmpl_1',
        title: 'Order #1234',
        body: '\$19.99 from Test Store',
        status: DeliveryStatus.submitted,
        fcmMessageId: 'fcm_msg_1',
        scheduledAt: DateTime.now(),
        fcmSubmittedAt: DateTime.now(),
        serverResponse: 'HTTP 200 - Accepted',
        isSimulated: true,
      );

      expect(history.status, equals(DeliveryStatus.submitted));
      expect(history.status.label, contains('FCM Accepted'));
      expect(history.isSimulated, isTrue);
    });
  });
}
