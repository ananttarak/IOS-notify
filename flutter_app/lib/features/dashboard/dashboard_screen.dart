import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/schedule_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/ios_notification_preview_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatCountdown(DateTime? target) {
    if (target == null) return '—';
    final now = DateTime.now();
    if (target.isBefore(now)) return 'Imminent';
    final diff = target.difference(now);
    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleProvider);
    final scheduleNotifier = ref.read(scheduleProvider.notifier);
    final history = ref.watch(historyProvider);
    final diagnostics = ref.watch(diagnosticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor = Colors.grey;
    String statusTitle = 'STOPPED';
    IconData statusIcon = Icons.stop_circle_rounded;

    if (schedule.emergencyStop) {
      statusColor = AppTheme.accentRed;
      statusTitle = 'EMERGENCY STOPPED';
      statusIcon = Icons.emergency_rounded;
    } else {
      switch (schedule.status) {
        case SchedulerStatus.running:
          statusColor = AppTheme.accentGreen;
          statusTitle = 'ACTIVE (AUTOMATING)';
          statusIcon = Icons.bolt_rounded;
          break;
        case SchedulerStatus.paused:
          statusColor = AppTheme.accentOrange;
          statusTitle = 'PAUSED';
          statusIcon = Icons.pause_circle_filled_rounded;
          break;
        case SchedulerStatus.stopped:
          statusColor = Colors.grey;
          statusTitle = 'STOPPED';
          statusIcon = Icons.stop_circle_rounded;
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('StorePulse'),
        actions: [
          IconButton(
            tooltip: 'Emergency Stop Toggle',
            icon: Icon(
              schedule.emergencyStop
                  ? Icons.lock_reset_rounded
                  : Icons.dangerous_rounded,
              color: schedule.emergencyStop
                  ? AppTheme.accentGreen
                  : AppTheme.accentRed,
            ),
            onPressed: () {
              scheduleNotifier.toggleEmergencyStop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(schedule.emergencyStop
                      ? 'Emergency Stop Deactivated'
                      : 'Global Emergency Stop Activated! All jobs halted.'),
                  backgroundColor: schedule.emergencyStop
                      ? AppTheme.accentGreen
                      : AppTheme.accentRed,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Status Banner Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [Colors.white, const Color(0xFFF8FAFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SCHEDULER STATUS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          Text(
                            statusTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Next countdown badge
                    if (schedule.status == SchedulerStatus.running &&
                        !schedule.emergencyStop)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFE5E5EA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'NEXT SEND',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _formatCountdown(schedule.nextPlannedSendTime),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                // Control Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text(
                          'Start',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: schedule.status == SchedulerStatus.running ||
                                schedule.emergencyStop
                            ? null
                            : () => scheduleNotifier.start(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.pause_rounded, size: 18),
                        label: const Text('Pause'),
                        onPressed: schedule.status != SchedulerStatus.running
                            ? null
                            : () => scheduleNotifier.pause(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accentRed,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.stop_rounded, size: 18),
                        label: const Text('Stop'),
                        onPressed: schedule.status == SchedulerStatus.stopped
                            ? null
                            : () => scheduleNotifier.stop(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Metrics & KPI Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Today Sent',
                  value: '${schedule.todayCount}',
                  subtitle: 'Max ${schedule.maxPerDay} / day',
                  icon: Icons.calendar_today_rounded,
                  accent: AppTheme.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'This Hour',
                  value: '${schedule.currentHourCount}',
                  subtitle: 'Max ${schedule.maxPerHour} / hr',
                  icon: Icons.timelapse_rounded,
                  accent: AppTheme.accentPurple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Target Device',
                  value: 'iPhone 18 Pro',
                  subtitle: diagnostics['hasFcmToken'] == true
                      ? 'FCM Registered'
                      : 'Mock Mode',
                  icon: Icons.phone_iphone_rounded,
                  accent: AppTheme.accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Interval Range',
                  value: '${schedule.minIntervalSeconds}-${schedule.maxIntervalSeconds}s',
                  subtitle: 'Randomized jitter',
                  icon: Icons.shuffle_rounded,
                  accent: AppTheme.accentOrange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 3. Quick Action: Test Push Notification
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppTheme.accentBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Push Notification',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Simulate instant lock-screen alert',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      await ref
                          .read(historyProvider.notifier)
                          .sendTestNotification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Test push dispatched! Check notification banner and History.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text('Send Test'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 4. Live iOS Notification Stream Preview (Inspired by reference video)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE LOCK-SCREEN STACK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Showing ${history.take(4).length} recent',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (history.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C1C1E)
                    : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFE5E5EA),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inbox_rounded, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No notifications in stream yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap "Start" or "Send Test" to populate lock-screen stream.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            Column(
              children: history.take(4).map((item) {
                final timeStr = DateFormat('h:mm a').format(item.scheduledAt);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: IosNotificationPreviewCard(
                    title: item.title,
                    body: item.body,
                    timestamp: timeStr,
                    isSimulated: item.isSimulated,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              Icon(icon, size: 16, color: accent),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
