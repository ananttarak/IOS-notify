import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';

class SchedulerScreen extends ConsumerStatefulWidget {
  const SchedulerScreen({super.key});

  @override
  ConsumerState<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends ConsumerState<SchedulerScreen> {
  late int _minInterval;
  late int _maxInterval;
  late int _maxPerHour;
  late int _maxPerDay;
  late String _timezone;
  late String _quietHoursStart;
  late String _quietHoursEnd;
  late int _duplicatePrevention;

  final List<String> _commonTimezones = [
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
    _minInterval = schedule.minIntervalSeconds;
    _maxInterval = schedule.maxIntervalSeconds;
    _maxPerHour = schedule.maxPerHour;
    _maxPerDay = schedule.maxPerDay;
    _timezone = schedule.timezone;
    _quietHoursStart = schedule.quietHoursStart;
    _quietHoursEnd = schedule.quietHoursEnd;
    _duplicatePrevention = schedule.duplicatePreventionMinutes;
  }

  void _saveSettings() {
    if (_minInterval > _maxInterval) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum interval cannot exceed maximum interval!'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    ref.read(scheduleProvider.notifier).updateSettings(
          minIntervalSeconds: _minInterval,
          maxIntervalSeconds: _maxInterval,
          maxPerHour: _maxPerHour,
          maxPerDay: _maxPerDay,
          timezone: _timezone,
          quietHoursStart: _quietHoursStart,
          quietHoursEnd: _quietHoursEnd,
          duplicatePreventionMinutes: _duplicatePrevention,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scheduler settings saved successfully!'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleProvider);
    final notifier = ref.read(scheduleProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduler Configuration'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Emergency Stop Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: schedule.emergencyStop
                  ? AppTheme.accentRed.withValues(alpha: 0.15)
                  : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: schedule.emergencyStop
                    ? AppTheme.accentRed
                    : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_rounded,
                  color: schedule.emergencyStop ? AppTheme.accentRed : AppTheme.accentGreen,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Global Emergency Stop',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        schedule.emergencyStop
                            ? 'All outbound jobs are halted globally.'
                            : 'Failsafe: Immediately halts all pushes.',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: schedule.emergencyStop,
                  activeTrackColor: AppTheme.accentRed,
                  onChanged: (_) => notifier.toggleEmergencyStop(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const Text(
            'INTERVAL & JITTER SETTINGS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          // Min & Max Interval sliders
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Minimum Interval (seconds):'),
                      Text('$_minInterval s',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: AppTheme.accentBlue)),
                    ],
                  ),
                  Slider(
                    value: _minInterval.toDouble(),
                    min: 10,
                    max: 600,
                    divisions: 59,
                    onChanged: (v) => setState(() => _minInterval = v.toInt()),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Maximum Interval (seconds):'),
                      Text('$_maxInterval s',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: AppTheme.accentBlue)),
                    ],
                  ),
                  Slider(
                    value: _maxInterval.toDouble(),
                    min: 20,
                    max: 1200,
                    divisions: 118,
                    onChanged: (v) => setState(() => _maxInterval = v.toInt()),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),
          const Text(
            'RATE LIMITING & CAPS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Max Notifications Per Hour:'),
                      Text('$_maxPerHour / hr',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: AppTheme.accentPurple)),
                    ],
                  ),
                  Slider(
                    value: _maxPerHour.toDouble(),
                    min: 1,
                    max: 120,
                    divisions: 119,
                    onChanged: (v) => setState(() => _maxPerHour = v.toInt()),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Max Notifications Per Day:'),
                      Text('$_maxPerDay / day',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: AppTheme.accentPurple)),
                    ],
                  ),
                  Slider(
                    value: _maxPerDay.toDouble(),
                    min: 5,
                    max: 500,
                    divisions: 99,
                    onChanged: (v) => setState(() => _maxPerDay = v.toInt()),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),
          const Text(
            'TIME ZONE & QUIET HOURS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Time Zone:'),
                      DropdownButton<String>(
                        value: _commonTimezones.contains(_timezone) ? _timezone : 'UTC',
                        underline: const SizedBox(),
                        items: _commonTimezones.map((tz) {
                          return DropdownMenuItem(value: tz, child: Text(tz));
                        }).toList(),
                        onChanged: (tz) {
                          if (tz != null) setState(() => _timezone = tz);
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quiet Hours Window:'),
                      Text('$_quietHoursStart — $_quietHoursEnd',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: AppTheme.accentOrange)),
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
                            }
                          },
                          child: Text('Start: $_quietHoursStart'),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                            }
                          },
                          child: Text('End: $_quietHoursEnd'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
