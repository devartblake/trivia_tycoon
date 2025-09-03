import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import '../../game/providers/riverpod_providers.dart';
import '../controllers/admin_filter_controller.dart';
import '../states/admin_filter_state.dart';

final adminFilterProvider = StateNotifierProvider<AdminFilterController, AdminFilterState>(
      (ref) => AdminFilterController(ref),
);

class AdminLeaderboardFilterScreen extends ConsumerWidget {
  const AdminLeaderboardFilterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminFilterProvider);
    final controller = ref.read(adminFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Leaderboard Filters'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Show Only Verified Users'),
            value: state.showVerified,
            onChanged: controller.setVerified,
          ),
          SwitchListTile(
            title: const Text('Show Only Premium Users'),
            value: state.showPremium,
            onChanged: controller.setPremium,
          ),
          SwitchListTile(
            title: const Text('Show Only Bot Accounts'),
            value: state.showBots,
            onChanged: controller.setBots,
          ),
          SwitchListTile(
            title: const Text('Show Only Power-up Holders'),
            value: state.showPowerUsers,
            onChanged: controller.setPowerUsers,
          ),
          const Divider(),
          const Text('Filter by Device Type'),
          Wrap(
            spacing: 10,
            children: ['Android', 'iOS', 'Web'].map((device) {
              return FilterChip(
                label: Text(device),
                selected: state.deviceTypes.contains(device),
                onSelected: (selected) {
                  controller.toggleDeviceType(device);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Preferred Notification Method'),
          DropdownButton<String>(
            value: state.notificationMethod,
            isExpanded: true,
            onChanged: controller.setNotificationMethod,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'email', child: Text('Email')),
              DropdownMenuItem(value: 'push', child: Text('Push')),
              DropdownMenuItem(value: 'sms', child: Text('SMS')),
              DropdownMenuItem(value: 'none', child: Text('None')),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              // You can trigger a filter refresh on the controller here.
              await ref.read(adminFilterProvider.notifier).saveToStorage();
              if (!context.mounted) return;
              Navigator.pop(context);

              // Trigger LeaderboardController refresh
              ref.read(leaderboardControllerProvider).applySorting(
                ref.read(leaderboardControllerProvider).sortBy,
              );
            },
            icon: const Icon(Icons.filter_alt),
            label: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}
