import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Container(
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.close_rounded, color: theme.primaryColor),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          'Filters',
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: theme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Advanced Filters',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Refine your leaderboard view',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // User Type Filters
                _buildSectionCard(
                  context: context,
                  title: 'User Types',
                  icon: Icons.people_rounded,
                  children: [
                    _buildModernSwitch(
                      context: context,
                      title: 'Verified Users',
                      subtitle: 'Show only verified accounts',
                      icon: Icons.verified_rounded,
                      value: state.showVerified,
                      onChanged: controller.setVerified,
                    ),
                    const SizedBox(height: 12),
                    _buildModernSwitch(
                      context: context,
                      title: 'Premium Users',
                      subtitle: 'Show only premium members',
                      icon: Icons.star_rounded,
                      value: state.showPremium,
                      onChanged: controller.setPremium,
                    ),
                    const SizedBox(height: 12),
                    _buildModernSwitch(
                      context: context,
                      title: 'Bot Accounts',
                      subtitle: 'Show only automated players',
                      icon: Icons.smart_toy_rounded,
                      value: state.showBots,
                      onChanged: controller.setBots,
                    ),
                    const SizedBox(height: 12),
                    _buildModernSwitch(
                      context: context,
                      title: 'Power Users',
                      subtitle: 'Show only power-up holders',
                      icon: Icons.bolt_rounded,
                      value: state.showPowerUsers,
                      onChanged: controller.setPowerUsers,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Device Type Filters
                _buildSectionCard(
                  context: context,
                  title: 'Device Types',
                  icon: Icons.devices_rounded,
                  children: [
                    Text(
                      'Filter by platform',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDeviceChip(
                          context: context,
                          label: 'Android',
                          icon: Icons.android_rounded,
                          selected: state.deviceTypes.contains('Android'),
                          onSelected: () => controller.toggleDeviceType('Android'),
                        ),
                        _buildDeviceChip(
                          context: context,
                          label: 'iOS',
                          icon: Icons.apple_rounded,
                          selected: state.deviceTypes.contains('iOS'),
                          onSelected: () => controller.toggleDeviceType('iOS'),
                        ),
                        _buildDeviceChip(
                          context: context,
                          label: 'Web',
                          icon: Icons.language_rounded,
                          selected: state.deviceTypes.contains('Web'),
                          onSelected: () => controller.toggleDeviceType('Web'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notification Method
                _buildSectionCard(
                  context: context,
                  title: 'Notification Method',
                  icon: Icons.notifications_rounded,
                  children: [
                    Text(
                      'Preferred notification channel',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.primaryColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: state.notificationMethod,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: theme.primaryColor,
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[900],
                          ),
                          onChanged: controller.setNotificationMethod,
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Row(
                                children: [
                                  Icon(Icons.select_all_rounded, size: 18),
                                  SizedBox(width: 12),
                                  Text('All Methods'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'email',
                              child: Row(
                                children: [
                                  Icon(Icons.email_rounded, size: 18),
                                  SizedBox(width: 12),
                                  Text('Email'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'push',
                              child: Row(
                                children: [
                                  Icon(Icons.notifications_active_rounded, size: 18),
                                  SizedBox(width: 12),
                                  Text('Push Notifications'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'sms',
                              child: Row(
                                children: [
                                  Icon(Icons.sms_rounded, size: 18),
                                  SizedBox(width: 12),
                                  Text('SMS'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'none',
                              child: Row(
                                children: [
                                  Icon(Icons.notifications_off_rounded, size: 18),
                                  SizedBox(width: 12),
                                  Text('None'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom Action Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(adminFilterProvider.notifier).saveToStorage();
                    if (!context.mounted) return;
                    context.pop();

                    ref.read(leaderboardControllerProvider).applySorting(
                      ref.read(leaderboardControllerProvider).sortBy,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle_rounded, size: 22),
                      SizedBox(width: 12),
                      Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernSwitch({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? theme.primaryColor.withValues(alpha: 0.08) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? theme.primaryColor.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: value
                  ? theme.primaryColor.withValues(alpha: 0.15)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: value ? theme.primaryColor : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? theme.primaryColor
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.primaryColor
                : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
