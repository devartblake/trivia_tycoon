import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/admin/providers/admin_auth_providers.dart';
import 'analytics/analytics_screen.dart';
import 'audit/admin_audit_log_screen.dart';
import 'config/config_settings_screen.dart';
import 'encryption/encryption_manager_screen.dart';
import 'events_management/admin_event_queue_screen.dart';
import 'notifications/admin_notifications_screen.dart';
import 'questions/file_import_export_screen.dart';
import 'questions/question_editor_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(unifiedIsAdminProvider);
    final theme = Theme.of(context);

    return isAdminAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _buildAccessDeniedScaffold(context),
      data: (isAdmin) {
        if (!isAdmin) {
          return _buildAccessDeniedScaffold(context);
        }
        final actions = _getAdminActions(context);

        // Get the screen width once using MediaQuery
        final screenWidth = MediaQuery.of(context).size.width;

        // Determine the responsive column count for the grid
        final int crossAxisCount;
        if (screenWidth > 1200) {
          crossAxisCount = 4;
        } else if (screenWidth > 800) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: CustomScrollView(
            slivers: [
              // This SliverAppBar section is correct
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.deepOrange[400]!,
                          Colors.orange[300]!,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_rounded,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Synaptix Command',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Manage your trivia empire',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // This SliverToBoxAdapter for stats is also correct
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildCombinedStatCard(
                    context: context,
                    stats: [
                      (
                        icon: Icons.category_rounded,
                        label: 'Modules',
                        value: '${actions.length}',
                        color: theme.primaryColor
                      ),
                      (
                        icon: Icons.verified_user_rounded,
                        label: 'Access',
                        value: 'Full',
                        color: Colors.green
                      ),
                      (
                        icon: Icons.question_answer_rounded,
                        label: 'Total Questions',
                        value: '1,204',
                        color: Colors.orange
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                // The SliverGrid is now the direct child of SliverPadding's 'sliver' property.
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    // Use the crossAxisCount we calculated above
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final action = actions[index];
                      return _buildActionCard(
                        context: context,
                        action: action,
                      );
                    },
                    childCount: actions.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccessDeniedScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 40),
              SizedBox(height: 12),
              Text(
                'Admin access required.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Your account does not currently have permission to open this screen.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
      {required BuildContext context, required _AdminAction action}) {
    return SizedBox(
      width: 280,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      action.icon,
                      size: 28,
                      color: action.color,
                    ),
                  ),

                  // Text Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        action.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // Arrow indicator
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: action.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: action.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCombinedStatCard(
      {required BuildContext context,
      required List<({IconData icon, String label, String value, Color color})>
          stats}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: stats[i].color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(stats[i].icon, size: 20, color: stats[i].color),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    stats[i].value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stats[i].label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_AdminAction> _getAdminActions(BuildContext context) {
    return [
      _AdminAction(
        title: 'Config Settings',
        subtitle: 'Update runtime and UI settings',
        icon: Icons.settings_rounded,
        color: Colors.blue,
        onTap: () => context.push('/admin/settings'),
      ),
      _AdminAction(
        title: 'Mission Analytics',
        subtitle: 'Mission engagement metrics',
        icon: Icons.analytics_rounded,
        color: Colors.purple,
        onTap: () => context.push('/admin/analytics'),
      ),
      _AdminAction(
        title: 'Notification',
        subtitle: 'Manage notifications',
        icon: Icons.style_rounded,
        color: Colors.teal,
        onTap: () => context.push('/admin/notifications'),
      ),
      _AdminAction(
        title: 'Card Demo',
        subtitle: 'Demonstration of card options',
        icon: Icons.style_rounded,
        color: Colors.teal,
        onTap: () => context.push('/admin/card-demo'),
      ),
      _AdminAction(
        title: 'Splash Selector',
        subtitle: 'Choose and preview animated splash screens',
        icon: Icons.play_circle_rounded,
        color: Colors.orange,
        onTap: () => context.push('/admin/splash-selector'),
      ),
      _AdminAction(
        title: 'Events Queue',
        subtitle: 'Manages the event queue',
        icon: Icons.event_busy_rounded,
        color: Colors.indigo,
        onTap: () => context.push('/admin/events'),
      ),
      _AdminAction(
        title: 'Audit Log',
        subtitle: 'User/question mutations and reprocess actions',
        icon: Icons.history_rounded,
        color: Colors.deepPurple,
        onTap: () => context.push('/admin/audit'),
      ),
      _AdminAction(
        title: 'Leaderboard Filters',
        subtitle: 'Advanced leaderboard filters',
        icon: Icons.filter_alt_rounded,
        color: Colors.indigo,
        onTap: () => context.push('/admin/leaderboard-filters'),
      ),
      _AdminAction(
        title: 'Encryption Manager',
        subtitle: 'Manage encryption keys and settings',
        icon: Icons.lock_rounded,
        color: Colors.red,
        onTap: () => context.push('/admin/encryption'),
      ),
      _AdminAction(
        title: 'File Import/Export',
        subtitle: 'Backup or restore quiz content',
        icon: Icons.upload_file_rounded,
        color: Colors.green,
        onTap: () => context.push('/admin/file-import-export'),
      ),
      _AdminAction(
        title: 'Questions List',
        subtitle: 'Browse and manage all questions',
        icon: Icons.list_alt_rounded,
        color: Colors.cyan,
        onTap: () => context.push('/admin/question-list'),
      ),
      _AdminAction(
        title: 'Audio Studio',
        subtitle: 'Manage music + SFX playback',
        icon: Icons.graphic_eq_rounded,
        color: Colors.deepOrange,
        onTap: () => context.push('/admin/audio-studio'),
      ),
      _AdminAction(
        title: 'Question Editor',
        subtitle: 'Add, edit, and delete questions',
        icon: Icons.edit_rounded,
        color: Colors.amber,
        onTap: () => context.push('/admin/question-editor'),
      ),
      _AdminAction(
        title: 'Store Inventory',
        subtitle: 'Stock policies, flash sales, rewards & overrides',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF6366F1),
        onTap: () => context.push('/admin/store'),
      ),
    ];
  }
}

class _AdminAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _AdminAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
