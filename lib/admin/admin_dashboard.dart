import 'package:flutter/material.dart';
import 'package:trivia_tycoon/admin/leaderboard/leaderboard_filter_screen.dart';
import 'package:trivia_tycoon/admin/questions/question_list_screen.dart';
import 'package:trivia_tycoon/admin/splash_screen/splash_selector_screen.dart';
import '../screens/widgets/slimy_card_preview_screen.dart';
import 'analytics/analytics_screen.dart';
import 'config/config_settings_screen.dart';
import 'encryption/encryption_manager_screen.dart';
import 'questions/file_import_export_screen.dart';
import 'questions/question_editor_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<_AdminAction> actions = [
      _AdminAction(
        title: 'Config Settings',
        subtitle: 'Update runtime and UI settings',
        icon: Icons.settings_rounded,
        color: Colors.blue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConfigSettingsScreen()),
        ),
      ),
      _AdminAction(
        title: 'Mission Analytics',
        subtitle: 'Mission engagement metrics',
        icon: Icons.analytics_rounded,
        color: Colors.purple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
        ),
      ),
      _AdminAction(
        title: 'Card Demo',
        subtitle: 'Demonstration of card options',
        icon: Icons.style_rounded,
        color: Colors.teal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SlimyCardPreviewScreen()),
        ),
      ),
      _AdminAction(
        title: 'Splash Selector',
        subtitle: 'Choose and preview animated splash screens',
        icon: Icons.play_circle_rounded,
        color: Colors.orange,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SplashSelectorScreen()),
        ),
      ),
      _AdminAction(
        title: 'Leaderboard Filters',
        subtitle: 'Advanced leaderboard filters',
        icon: Icons.filter_alt_rounded,
        color: Colors.indigo,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminLeaderboardFilterScreen()),
        ),
      ),
      _AdminAction(
        title: 'Encryption Manager',
        subtitle: 'Manage encryption keys and settings',
        icon: Icons.lock_rounded,
        color: Colors.red,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EncryptionManagerScreen()),
        ),
      ),
      _AdminAction(
        title: 'File Import/Export',
        subtitle: 'Backup or restore quiz content',
        icon: Icons.upload_file_rounded,
        color: Colors.green,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FileImportExportScreen()),
        ),
      ),
      _AdminAction(
        title: 'Questions List',
        subtitle: 'Browse and manage all questions',
        icon: Icons.list_alt_rounded,
        color: Colors.cyan,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuestionListScreen()),
        ),
      ),
      _AdminAction(
        title: 'Question Editor',
        subtitle: 'Add, edit, and delete questions',
        icon: Icons.edit_rounded,
        color: Colors.amber,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuestionEditorScreen()),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern gradient app bar
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your trivia empire',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      icon: Icons.category_rounded,
                      label: 'Modules',
                      value: '${actions.length}',
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      icon: Icons.verified_user_rounded,
                      label: 'Access',
                      value: 'Full',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Cards Grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
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
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required _AdminAction action,
  }) {
    return Material(
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
                color: Colors.black.withOpacity(0.04),
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
                    color: action.color.withOpacity(0.1),
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
                      color: action.color.withOpacity(0.1),
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
    );
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
