import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/notification_history_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';
  DeliveryStatus? _selectedStatusFilter;

  @override
  Widget build(BuildContext context) {
    final historyList = ref.watch(historyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredList = historyList.where((item) {
      if (_selectedStatusFilter != null && item.status != _selectedStatusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchBody = item.body.toLowerCase().contains(query);
        return matchTitle || matchBody;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification History'),
        actions: [
          if (historyList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear History',
              onPressed: () {
                ref.read(historyProvider.notifier).clearHistory();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search title or body...',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedStatusFilter == null,
                  onSelected: (_) => setState(() => _selectedStatusFilter = null),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('FCM Submitted'),
                  selected: _selectedStatusFilter == DeliveryStatus.submitted,
                  onSelected: (_) => setState(
                      () => _selectedStatusFilter = DeliveryStatus.submitted),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Delivered'),
                  selected: _selectedStatusFilter == DeliveryStatus.delivered,
                  onSelected: (_) => setState(
                      () => _selectedStatusFilter = DeliveryStatus.delivered),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Rate Limited'),
                  selected: _selectedStatusFilter == DeliveryStatus.skippedRateLimited,
                  onSelected: (_) => setState(() =>
                      _selectedStatusFilter = DeliveryStatus.skippedRateLimited),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Failed'),
                  selected: _selectedStatusFilter == DeliveryStatus.failed,
                  onSelected: (_) =>
                      setState(() => _selectedStatusFilter = DeliveryStatus.failed),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text(
                          'No history records found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _buildHistoryCard(context, item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, NotificationHistoryModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color badgeColor;
    IconData badgeIcon;

    switch (item.status) {
      case DeliveryStatus.submitted:
        badgeColor = AppTheme.accentBlue;
        badgeIcon = Icons.cloud_done_rounded;
        break;
      case DeliveryStatus.delivered:
        badgeColor = AppTheme.accentGreen;
        badgeIcon = Icons.done_all_rounded;
        break;
      case DeliveryStatus.failed:
        badgeColor = AppTheme.accentRed;
        badgeIcon = Icons.error_outline_rounded;
        break;
      case DeliveryStatus.skippedRateLimited:
      case DeliveryStatus.skippedQuietHours:
        badgeColor = AppTheme.accentOrange;
        badgeIcon = Icons.block_rounded;
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.access_time_rounded;
    }

    final dateStr = DateFormat('MMM d, h:mm:ss a').format(item.scheduledAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.all(14),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(badgeIcon, color: badgeColor, size: 18),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(item.body, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.status.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Status Detail:', item.status.label),
                if (item.fcmMessageId != null)
                  _detailRow('FCM Message ID:', item.fcmMessageId!),
                if (item.fcmSubmittedAt != null)
                  _detailRow(
                    'Gateway Submitted:',
                    DateFormat('yyyy-MM-dd HH:mm:ss').format(item.fcmSubmittedAt!),
                  ),
                if (item.confirmedDeliveredAt != null)
                  _detailRow(
                    'Confirmed Delivered:',
                    DateFormat('yyyy-MM-dd HH:mm:ss').format(item.confirmedDeliveredAt!),
                  ),
                if (item.serverResponse != null)
                  _detailRow('Server Response:', item.serverResponse!),
                if (item.errorMessage != null)
                  _detailRow('Error Message:', item.errorMessage!),
                if (item.diagnostics.isNotEmpty)
                  _detailRow('Diagnostics:', item.diagnostics.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
