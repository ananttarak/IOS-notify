import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/schedule_model.dart';
import '../../core/models/template_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../templates/template_editor_modal.dart';
import 'widgets/ios_notification_preview_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _countdownTimer;

  // 4-Slider & Order sequence state
  int _notificationsPerInterval = 10; // Slider 1: Notifications count (e.g. 10)
  int _intervalMinutes = 1;          // Slider 2: Minutes window (e.g. 1 or 2 min)
  double _minOrderAmount = 2000.0;    // Slider 3: Start Amount (₹)
  double _maxOrderAmount = 5000.0;    // Slider 4: End Amount (₹)
  int _startOrderNumber = 1794;      // Sequential order number starting point
  String _storeName = 'Folkthreads';

  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  late TextEditingController _orderNumController;
  late TextEditingController _storeNameController;

  int _minInterval = 15;
  int _maxInterval = 60;
  int _maxPerHour = 50000;
  int _maxPerDay = 500000;
  String _timezone = 'UTC';
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '07:00';

  final List<String> _timezones = [
    'UTC',
    'America/New_York',
    'America/Los_Angeles',
    'America/Chicago',
    'Europe/London',
    'Europe/Paris',
    'Asia/Kolkata',
    'Asia/Tokyo',
    'Asia/Singapore',
    'Australia/Sydney',
  ];

  @override
  void initState() {
    super.initState();
    final schedule = ref.read(scheduleProvider);
    _notificationsPerInterval = schedule.notificationsPerInterval;
    _intervalMinutes = schedule.intervalMinutes;
    _minOrderAmount = schedule.minOrderAmount;
    _maxOrderAmount = schedule.maxOrderAmount;
    _startOrderNumber = schedule.startOrderNumber;
    _storeName = schedule.storeName;

    _minAmountController =
        TextEditingController(text: _minOrderAmount.toStringAsFixed(0));
    _maxAmountController =
        TextEditingController(text: _maxOrderAmount.toStringAsFixed(0));
    _orderNumController =
        TextEditingController(text: '$_startOrderNumber');
    _storeNameController = TextEditingController(text: _storeName);

    _minInterval = schedule.minIntervalSeconds;
    _maxInterval = schedule.maxIntervalSeconds;
    _maxPerHour = schedule.maxPerHour;
    _maxPerDay = schedule.maxPerDay;
    _timezone = schedule.timezone;
    _quietHoursStart = schedule.quietHoursStart;
    _quietHoursEnd = schedule.quietHoursEnd;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _orderNumController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  String _formatCountdown(DateTime? target) {
    if (target == null) return '—';
    final now = DateTime.now();
    if (target.isBefore(now)) return 'Sending...';
    final diff = target.difference(now);
    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _saveAdminSettings() {
    final cleanMinStr = _minAmountController.text
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .trim();
    final cleanMaxStr = _maxAmountController.text
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .trim();
    final parsedMin = double.tryParse(cleanMinStr) ?? _minOrderAmount;
    final parsedMax = double.tryParse(cleanMaxStr) ?? _maxOrderAmount;
    final cleanOrderStr =
        _orderNumController.text.replaceAll('#', '').trim();
    final parsedOrderNum = int.tryParse(cleanOrderStr) ?? _startOrderNumber;
    final store = _storeNameController.text.trim().isNotEmpty
        ? _storeNameController.text.trim()
        : _storeName;

    setState(() {
      _minOrderAmount = parsedMin;
      _maxOrderAmount = parsedMax;
      _startOrderNumber = parsedOrderNum;
      _storeName = store;
    });

    ref
        .read(templatesProvider.notifier)
        .updateCustomAmount('₹${parsedMin.toStringAsFixed(2)}');
    ref.read(templatesProvider.notifier).updateStartOrderNumber(parsedOrderNum);
    ref.read(templatesProvider.notifier).updateStoreName(store);

    ref.read(scheduleProvider.notifier).updateSettings(
          notificationsPerInterval: _notificationsPerInterval,
          intervalMinutes: _intervalMinutes,
          minOrderAmount: _minOrderAmount,
          maxOrderAmount: _maxOrderAmount,
          orderAmount: _maxOrderAmount,
          startOrderNumber: _startOrderNumber,
          storeName: _storeName,
          minIntervalSeconds: _minInterval,
          maxIntervalSeconds: _maxInterval,
          maxPerHour: _maxPerHour,
          maxPerDay: _maxPerDay,
          timezone: _timezone,
          quietHoursStart: _quietHoursStart,
          quietHoursEnd: _quietHoursEnd,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order & automation settings updated!'),
        backgroundColor: AppTheme.accentGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleProvider);
    final scheduleNotifier = ref.read(scheduleProvider.notifier);
    final templates = ref.watch(templatesProvider);
    final templateNotifier = ref.read(templatesProvider.notifier);
    final history = ref.watch(historyProvider);
    final diagnostics = ref.watch(diagnosticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor = Colors.grey;
    String statusTitle = 'STOPPED';
    IconData statusIcon = Icons.stop_circle_rounded;

    if (schedule.emergencyStop) {
      statusColor = AppTheme.accentRed;
      statusTitle = 'EMERGENCY STOP';
      statusIcon = Icons.shield_rounded;
    } else {
      switch (schedule.status) {
        case SchedulerStatus.running:
          statusColor = const Color(0xFF10B981);
          statusTitle = 'ACTIVE • LIVE STREAM';
          statusIcon = Icons.bolt_rounded;
          break;
        case SchedulerStatus.paused:
          statusColor = const Color(0xFFFF9500);
          statusTitle = 'AUTOMATION PAUSED';
          statusIcon = Icons.pause_circle_filled_rounded;
          break;
        case SchedulerStatus.stopped:
          statusColor = Colors.grey;
          statusTitle = 'SYSTEM IDLE';
          statusIcon = Icons.radio_button_checked_rounded;
          break;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF0F4F8),
      body: Stack(
        children: [
          // 1. Ambient Glassmorphic Glow Orbs
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.22 : 0.15),
              ),
            ),
          ),
          Positioned(
            top: 250,
            right: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.18 : 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 20,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.15 : 0.10),
              ),
            ),
          ),

          // 2. Blur Veil
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: const SizedBox.expand(),
          ),

          // 3. Scrollable Content
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              children: [
                // Top Store Bar
                _buildTopStoreHeader(context, schedule, scheduleNotifier, isDark),
                const SizedBox(height: 14),

                // iOS Web Push & Audio Banner
                if (kIsWeb) ...[
                  _buildIosWebPushBanner(context, isDark),
                  const SizedBox(height: 14),
                ],

                // Hero Status & Real-Time Glass Banner
                _buildLiveStatusHeroCard(context, schedule, scheduleNotifier,
                    statusTitle, statusColor, statusIcon, isDark),
                const SizedBox(height: 16),

                // Glass Metrics Grid (Orders, GMV, Hourly, Countdown)
                _buildMetricsGrid(context, schedule, isDark),
                const SizedBox(height: 18),

                // Action Bar: Instant Push & Controls
                _buildPrimaryControlsBar(
                    context, schedule, scheduleNotifier, isDark),
                const SizedBox(height: 24),

                // Shopify Lock Screen Live Preview Mockup
                _buildInteractiveLockScreenFrame(
                    context, history, isDark, schedule.status == SchedulerStatus.running),
                const SizedBox(height: 28),

                // Admin Settings Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.tune_rounded,
                          color: Color(0xFF6366F1), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'ADMIN STORE CONTROLS & SETTINGS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Admin Panel: Timing, Jitter & Caps
                _buildIntervalsAndCapsGlassCard(context, isDark),
                const SizedBox(height: 16),

                // Admin Panel: Timezone & Quiet Hours
                _buildTimezoneAndQuietHoursGlassCard(context, isDark),
                const SizedBox(height: 16),

                // Admin Panel: Template Studio Quick Manager
                _buildTemplatesQuickManagerGlassCard(
                    context, templates, templateNotifier, isDark),
                const SizedBox(height: 16),

                // Admin Panel: Device & Cloud Diagnostics
                _buildDiagnosticsGlassCard(context, diagnostics, isDark),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- GLASSMORPHIC CONTAINER HELPER ---
  Widget _glassCard({
    required Widget child,
    required bool isDark,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    Color? borderColor,
  }) {
    final radius = borderRadius ?? BorderRadius.circular(22);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF1E2638).withValues(alpha: 0.70),
                      const Color(0xFF111726).withValues(alpha: 0.55),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.85),
                      Colors.white.withValues(alpha: 0.65),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: borderColor ??
                  (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.80)),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : const Color(0xFF64748B).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // 0. iOS Web Push & Audio Banner
  Widget _buildIosWebPushBanner(BuildContext context, bool isDark) {
    return _glassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(18),
      borderColor: const Color(0xFF6366F1).withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active_rounded,
                    color: Color(0xFF818CF8), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'iOS 16.4+ Web Push & Audio Engine',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Enables system banners & authentic Shopify register chimes',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.notifications_rounded, size: 16),
                  label: const Text(
                    'Enable Notifications',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final granted = await LocalNotificationService.instance
                        .requestPermission();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(granted
                              ? 'Notifications & Audio Activated!'
                              : 'Notification permission requested/updated.'),
                          backgroundColor: granted
                              ? AppTheme.accentGreen
                              : const Color(0xFF6366F1),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.volume_up_rounded, size: 16),
                  label: const Text(
                    'Test Sound',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    LocalNotificationService.instance.playChime();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_outlined,
                    size: 15, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'For Lock-Screen alerts: In Safari, tap Share ⎋ → "Add to Home Screen" and open from your Home Screen.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Top Store Header
  Widget _buildTopStoreHeader(BuildContext context, ScheduleModel schedule,
      ScheduleNotifier notifier, bool isDark) {
    return Row(
      children: [
        // Glowing Shopify Store Avatar with transparent official logo
        Container(
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/shopify_icon.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Shopify',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${schedule.storeName} • Online Store',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        // Emergency Stop Pill
        IconButton(
          tooltip: 'Toggle Global Emergency Stop',
          style: IconButton.styleFrom(
            backgroundColor: schedule.emergencyStop
                ? AppTheme.accentRed.withValues(alpha: 0.2)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05)),
          ),
          icon: Icon(
            schedule.emergencyStop
                ? Icons.lock_reset_rounded
                : Icons.power_settings_new_rounded,
            color: schedule.emergencyStop
                ? AppTheme.accentRed
                : (isDark ? Colors.white70 : Colors.black87),
          ),
          onPressed: () => notifier.toggleEmergencyStop(),
        ),
      ],
    );
  }

  // 2. Live Status Hero Card
  Widget _buildLiveStatusHeroCard(
      BuildContext context,
      ScheduleModel schedule,
      ScheduleNotifier notifier,
      String statusTitle,
      Color statusColor,
      IconData statusIcon,
      bool isDark) {
    return _glassCard(
      isDark: isDark,
      borderColor: statusColor.withValues(alpha: 0.35),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AUTOMATION ENGINE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Next Send Badge
              if (schedule.status == SchedulerStatus.running &&
                  !schedule.emergencyStop)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'NEXT DISPATCH',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        _formatCountdown(schedule.nextPlannedSendTime),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Instant Test Order Dispatch Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.notifications_active_rounded,
                  color: Colors.white, size: 20),
              label: const Text(
                '🔔 SEND TEST ORDER NOTIFICATION',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: () {
                ref.read(historyProvider.notifier).sendTestNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Test order dispatched! Sound played.'),
                    backgroundColor: Color(0xFF10B981),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Action Buttons Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text(
                    'Start Stream',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onPressed: schedule.status == SchedulerStatus.running ||
                          schedule.emergencyStop
                      ? null
                      : () => notifier.start(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: schedule.status != SchedulerStatus.running
                      ? null
                      : () => notifier.pause(),
                  child: const Text('Pause'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentRed,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: schedule.status == SchedulerStatus.stopped
                      ? null
                      : () => notifier.stop(),
                  child: const Text('Stop'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Glass Metrics KPI Grid
  Widget _buildMetricsGrid(
      BuildContext context, ScheduleModel schedule, bool isDark) {
    final rupeeFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final estGmv = rupeeFormat.format(schedule.todayCount * 2490);

    return Row(
      children: [
        Expanded(
          child: _metricBox(
            title: 'Orders Sent',
            value: '${schedule.todayCount}',
            sub: 'Max ${schedule.maxPerDay} / day',
            icon: Icons.shopping_bag_outlined,
            accent: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricBox(
            title: 'Hourly Pace',
            value: '${schedule.currentHourCount}',
            sub: 'Cap: ${schedule.maxPerHour} / hr',
            icon: Icons.speed_rounded,
            accent: const Color(0xFF6366F1),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricBox(
            title: 'Simulated GMV',
            value: estGmv,
            sub: 'Est. Activity Volume',
            icon: Icons.trending_up_rounded,
            accent: const Color(0xFF06B6D4),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _metricBox({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color accent,
    required bool isDark,
  }) {
    return _glassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              Icon(icon, size: 15, color: accent),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Primary Quick Push Action Bar
  Widget _buildPrimaryControlsBar(BuildContext context, ScheduleModel schedule,
      ScheduleNotifier notifier, bool isDark) {
    return _glassCard(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flash_on_rounded,
                color: Color(0xFF0284C7), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instant Test Dispatch',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Fire a test order notification immediately',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await ref.read(historyProvider.notifier).sendTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test order dispatched to stream!'),
                    backgroundColor: Color(0xFF0284C7),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Send Test'),
          ),
        ],
      ),
    );
  }

  // 5. Interactive iPhone Lock Screen Mockup (Shopify reference stream)
  Widget _buildInteractiveLockScreenFrame(
      BuildContext context, List history, bool isDark, bool isStreaming) {
    final nowTime = DateFormat('h:mm').format(DateTime.now());
    final nowDate = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return _glassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(28),
      borderColor: const Color(0xFF10B981).withValues(alpha: 0.25),
      child: Column(
        children: [
          // iPhone Island & Header Mockup
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isStreaming
                          ? const Color(0xFF10B981)
                          : Colors.grey.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isStreaming ? 'LIVE NOTIFICATION STREAM' : 'LOCK SCREEN STREAM',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Text(
                'iPhone 18 Pro Preview',
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Lock Screen Clock
          Column(
            children: [
              Text(
                nowDate,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              Text(
                nowTime,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -1.0,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stream Notifications List
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IosNotificationPreviewCard(
                title: 'Order #$_startOrderNumber',
                body:
                    '₹${_minOrderAmount.toStringAsFixed(2)}, 1 item from Online Store •\n$_storeName',
                timestamp: '8m ago',
              ),
            )
          else
            Column(
              children: history.take(6).map((item) {
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

  // 6. Admin Settings Section: 3-Slider Automation Controls & Order Customization
  Widget _buildIntervalsAndCapsGlassCard(BuildContext context, bool isDark) {
    final rateSeconds = (_intervalMinutes * 60) / _notificationsPerInterval;

    return _glassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Automation (3-Sliders)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Save Settings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: _saveAdminSettings,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // SLIDER 1: Notifications Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Slider 1: Notifications Count',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_notificationsPerInterval notifications',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _notificationsPerInterval.toDouble().clamp(1, 100),
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: const Color(0xFF10B981),
            onChanged: (v) =>
                setState(() => _notificationsPerInterval = v.toInt()),
            onChangeEnd: (_) => _saveAdminSettings(),
          ),
          Row(
            children: [
              for (final preset in [5, 10, 25, 50, 100]) ...[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ChoiceChip(
                      label: Text(
                        '$preset',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _notificationsPerInterval == preset
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _notificationsPerInterval == preset
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: _notificationsPerInterval == preset,
                      selectedColor: const Color(0xFF10B981),
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _notificationsPerInterval = preset);
                          _saveAdminSettings();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),

          const Divider(height: 22),

          // SLIDER 2: Time Window in Minutes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Slider 2: Time Window (Minutes)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_intervalMinutes min',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _intervalMinutes.toDouble().clamp(1, 10),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: const Color(0xFF6366F1),
            onChanged: (v) => setState(() => _intervalMinutes = v.toInt()),
            onChangeEnd: (_) => _saveAdminSettings(),
          ),
          Row(
            children: [
              for (final preset in [1, 2, 3, 5]) ...[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ChoiceChip(
                      label: Text(
                        '$preset min',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _intervalMinutes == preset
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _intervalMinutes == preset
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: _intervalMinutes == preset,
                      selectedColor: const Color(0xFF6366F1),
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _intervalMinutes = preset);
                          _saveAdminSettings();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.speed_rounded,
                    color: Color(0xFF6366F1), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚡ Rate: $_notificationsPerInterval orders every $_intervalMinutes min (1 order every ${rateSeconds.toStringAsFixed(1)} seconds)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 22),

          // SLIDER 3 & 4: AUTHENTIC RANDOM AMOUNT RANGE (Start Amount & End Amount)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Realistic Order Amount Range',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹${_minOrderAmount.toStringAsFixed(0)} – ₹${_maxOrderAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF59E0B),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Each simulated notification randomly picks an authentic order amount within this range.',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),

          // Slider 3: Start Amount (Min)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Slider 3: Start Amount (Min)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
              Text(
                '₹${_minOrderAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
              ),
            ],
          ),
          Slider(
            value: _minOrderAmount.clamp(500, 50000),
            min: 500,
            max: 50000,
            divisions: 99,
            activeColor: const Color(0xFFF59E0B),
            onChanged: (v) {
              setState(() {
                _minOrderAmount = v;
                _minAmountController.text = v.toStringAsFixed(0);
                if (_maxOrderAmount < _minOrderAmount) {
                  _maxOrderAmount = _minOrderAmount;
                  _maxAmountController.text = _minOrderAmount.toStringAsFixed(0);
                }
              });
            },
            onChangeEnd: (_) => _saveAdminSettings(),
          ),

          // Slider 4: End Amount (Max)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Slider 4: End Amount (Max)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
              Text(
                '₹${_maxOrderAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
              ),
            ],
          ),
          Slider(
            value: _maxOrderAmount.clamp(500, 100000),
            min: 500,
            max: 100000,
            divisions: 199,
            activeColor: const Color(0xFF10B981),
            onChanged: (v) {
              setState(() {
                _maxOrderAmount = v;
                _maxAmountController.text = v.toStringAsFixed(0);
                if (_minOrderAmount > _maxOrderAmount) {
                  _minOrderAmount = _maxOrderAmount;
                  _minAmountController.text = _maxOrderAmount.toStringAsFixed(0);
                }
              });
            },
            onChangeEnd: (_) => _saveAdminSettings(),
          ),

          // Direct Custom Start & End Amount Text Inputs
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Start Amount (₹)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onChanged: (text) {
                    final clean = text.replaceAll('₹', '').replaceAll(',', '').trim();
                    final parsed = double.tryParse(clean);
                    if (parsed != null) {
                      setState(() => _minOrderAmount = parsed.clamp(1, 1000000));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'End Amount (₹)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onChanged: (text) {
                    final clean = text.replaceAll('₹', '').replaceAll(',', '').trim();
                    final parsed = double.tryParse(clean);
                    if (parsed != null) {
                      setState(() => _maxOrderAmount = parsed.clamp(1, 1000000));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onPressed: _saveAdminSettings,
                child: const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Quick Presets
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ActionChip(
                label: const Text('₹1k – ₹5k', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  setState(() {
                    _minOrderAmount = 1000;
                    _maxOrderAmount = 5000;
                    _minAmountController.text = '1000';
                    _maxAmountController.text = '5000';
                  });
                  _saveAdminSettings();
                },
              ),
              ActionChip(
                label: const Text('₹2k – ₹5k', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  setState(() {
                    _minOrderAmount = 2000;
                    _maxOrderAmount = 5000;
                    _minAmountController.text = '2000';
                    _maxAmountController.text = '5000';
                  });
                  _saveAdminSettings();
                },
              ),
              ActionChip(
                label: const Text('₹3k – ₹10k', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  setState(() {
                    _minOrderAmount = 3000;
                    _maxOrderAmount = 10000;
                    _minAmountController.text = '3000';
                    _maxAmountController.text = '10000';
                  });
                  _saveAdminSettings();
                },
              ),
              ActionChip(
                label: const Text('₹5k – ₹25k', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  setState(() {
                    _minOrderAmount = 5000;
                    _maxOrderAmount = 25000;
                    _minAmountController.text = '5000';
                    _maxAmountController.text = '25000';
                  });
                  _saveAdminSettings();
                },
              ),
              ActionChip(
                label: const Text('Exact ₹6,555', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  setState(() {
                    _minOrderAmount = 6555;
                    _maxOrderAmount = 6555;
                    _minAmountController.text = '6555';
                    _maxAmountController.text = '6555';
                  });
                  _saveAdminSettings();
                },
              ),
            ],
          ),

          const Divider(height: 22),

          // SEQUENTIAL ORDER NUMBERING & STORE INFO
          const Text(
            'Order Sequence Progression (1 by 1)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          const SizedBox(height: 6),
          Text(
            'Orders follow one by one in sequence (e.g. #$_startOrderNumber, #${_startOrderNumber + 1}, #${_startOrderNumber + 2}...)',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _orderNumController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Starting Order #',
                    prefixText: '#',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onChanged: (text) {
                    final parsed = int.tryParse(text.replaceAll('#', '').trim());
                    if (parsed != null) {
                      setState(() => _startOrderNumber = parsed);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _storeNameController,
                  decoration: InputDecoration(
                    labelText: 'Store Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7. Admin Settings Section: Timezone & Quiet Hours
  Widget _buildTimezoneAndQuietHoursGlassCard(
      BuildContext context, bool isDark) {
    return _glassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time Zone & Quiet Hours',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Timezone Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Store Time Zone:'),
              DropdownButton<String>(
                value: _timezones.contains(_timezone) ? _timezone : 'UTC',
                underline: const SizedBox(),
                items: _timezones.map((tz) {
                  return DropdownMenuItem(value: tz, child: Text(tz));
                }).toList(),
                onChanged: (tz) {
                  if (tz != null) {
                    setState(() => _timezone = tz);
                    _saveAdminSettings();
                  }
                },
              ),
            ],
          ),
          const Divider(height: 16),

          // Quiet Hours Pickers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quiet Hours Window:'),
              Text('$_quietHoursStart — $_quietHoursEnd',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFFFF9500))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 22, minute: 0),
                    );
                    if (time != null) {
                      setState(() {
                        _quietHoursStart =
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      });
                      _saveAdminSettings();
                    }
                  },
                  child: Text('Start: $_quietHoursStart'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 7, minute: 0),
                    );
                    if (time != null) {
                      setState(() {
                        _quietHoursEnd =
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      });
                      _saveAdminSettings();
                    }
                  },
                  child: Text('End: $_quietHoursEnd'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 8. Admin Settings Section: Templates Quick Manager
  Widget _buildTemplatesQuickManagerGlassCard(
      BuildContext context,
      List<TemplateModel> templates,
      TemplatesNotifier notifier,
      bool isDark) {
    return _glassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notification Templates',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded,
                    color: Color(0xFF10B981)),
                tooltip: 'Add New Template',
                onPressed: () {
                  TemplateEditorModal.show(
                    context,
                    onSave: (newTemplate) => notifier.addTemplate(newTemplate),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          Column(
            children: templates.map((tmpl) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'W:${tmpl.weight}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tmpl.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            tmpl.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: tmpl.isEnabled,
                      activeTrackColor: const Color(0xFF10B981),
                      onChanged: (_) => notifier.toggleEnabled(tmpl.id),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 9. Admin Settings Section: Device & Cloud Diagnostics
  Widget _buildDiagnosticsGlassCard(
      BuildContext context, Map<String, dynamic> diagnostics, bool isDark) {
    final devId = diagnostics['deviceId']?.toString() ?? 'unknown_device';

    return _glassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device & Cloud Diagnostics',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _diagRow(
            'Persistent Device ID',
            devId.length > 20 ? '${devId.substring(0, 18)}...' : devId,
            canCopy: true,
            copyVal: devId,
            isDark: isDark,
          ),
          _diagRow(
            'Firebase Core',
            diagnostics['isFirebaseInitialized'] == true
                ? 'Connected (Live)'
                : 'Local Mode',
            isDark: isDark,
            badgeColor: diagnostics['isFirebaseInitialized'] == true
                ? const Color(0xFF10B981)
                : const Color(0xFFFF9500),
          ),
          _diagRow(
            'FCM Gateway Target',
            diagnostics['hasFcmToken'] == true ? 'Registered' : 'Mock Streamer',
            isDark: isDark,
            badgeColor: diagnostics['hasFcmToken'] == true
                ? const Color(0xFF10B981)
                : const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _diagRow(String label, String value,
      {bool canCopy = false,
      String? copyVal,
      Color? badgeColor,
      required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54)),
          Row(
            children: [
              if (badgeColor != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeColor),
                  ),
                )
              else
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600),
                ),
              if (canCopy)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: copyVal ?? value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Device ID copied to clipboard!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
