import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/notification_history_store.dart';
import '../../../game/providers/notification_providers.dart';
import 'package:intl/intl.dart';

class HistoryList extends ConsumerWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(notificationHistoryProvider);
    final df = DateFormat('MMM d, h:mm a');

    return history.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No history yet.'),
            ),
          );
        }
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (_, i) {
              final e = entries[i] as NotificationHistoryEntry;
              return ListTile(
                leading: Icon(_iconForType(e.type)),
                title: Text('${e.title} • ${e.channelKey}'),
                subtitle: Text('${df.format(e.timestamp)}\n${e.body}'),
                isThreeLine: true,
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: entries.length,
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('History error: $e'),
    );
  }

  IconData _iconForType(String t) {
    switch (t) {
      case 'created':
        return Icons.add_alert_outlined;
      case 'displayed':
        return Icons.notifications_active_outlined;
      case 'dismissed':
        return Icons.close;
      case 'action':
        return Icons.touch_app_outlined;
      case 'sentNow':
        return Icons.flash_on_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }
}
