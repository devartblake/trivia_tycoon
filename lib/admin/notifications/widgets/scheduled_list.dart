import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/notification_service.dart';
import '../../../game/providers/notification_providers.dart';

class ScheduledList extends ConsumerWidget {
  final DateFormat dateFormat;
  const ScheduledList({super.key, required this.dateFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledAsync = ref.watch(scheduledProvider);

    return scheduledAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _EmptyState(
            icon: Icons.event_busy_outlined,
            message: 'No scheduled notifications.',
            hint: 'Use "Schedule" to create one.',
          );
        }
        return Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = items[i];
              final schedule = n.schedule;
              return ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: Text(n.content?.title ?? '(no title)'),
                subtitle: schedule == null
                    ? const Text('Scheduled')
                    : FutureBuilder<DateTime?>(
                        future: NotificationService().getNextFireTime(schedule),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Text('Computing next run…');
                          }
                          final dt = snap.data;
                          return Text(dt != null ? dateFormat.format(dt) : '—');
                        },
                      ),
                trailing: IconButton(
                  tooltip: 'Cancel',
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    final id = n.content?.id;
                    if (id != null) {
                      await NotificationService().cancel(id);
                      ref.invalidate(scheduledProvider);
                    }
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Text('Failed to load scheduled: $e'),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? hint;
  const _EmptyState({required this.icon, required this.message, this.hint});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.bodyLarge),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(hint!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey)),
            ]
          ],
        ),
      ),
    );
  }
}
