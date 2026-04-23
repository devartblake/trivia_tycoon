import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_store_providers.dart';
import '../widgets/reward_limit_editor.dart';

class AdminRewardLimitsScreen extends ConsumerWidget {
  const AdminRewardLimitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitsAsync = ref.watch(adminRewardLimitsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Reward Limits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminRewardLimitsProvider),
          ),
        ],
      ),
      body: limitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFFEF4444), size: 32),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminRewardLimitsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (limits) {
          if (limits.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No reward limits configured.',
                    style: TextStyle(color: Colors.grey)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: limits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => RewardLimitEditor(
              initial: limits[i],
              onSave: (updated) async {
                await ref
                    .read(adminStoreServiceProvider)
                    .updateRewardLimit(updated);
                ref.invalidate(adminRewardLimitsProvider);
              },
            ),
          );
        },
      ),
    );
  }
}
