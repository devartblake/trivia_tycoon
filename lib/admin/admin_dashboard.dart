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
    final List<_AdminAction> actions = [
      _AdminAction(
        title: '⚙️ Config Settings',
        subtitle: 'Update runtime and UI settings',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConfigSettingsScreen()),
        ),
      ),
      _AdminAction(
        title: 'Mission Analytics',
        subtitle: 'Mission Engagement Metrics',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
        ),
      ),
      _AdminAction(
        title: 'Card Demo',
        subtitle: 'Demonstration of cards options',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SlimyCardPreviewScreen()),
        ),
      ),
      _AdminAction(
        title: '🎬 Splash Selector',
        subtitle: 'Choose and preview animated splash screens',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SplashSelectorScreen()),
        ),
      ),
      _AdminAction(
        title: 'Leaderboard Filters',
        subtitle: 'Advanced Leaderboard Filters',
        onTap: ()=> Navigator.push(
          context,
          MaterialPageRoute(builder: (_) =>  const AdminLeaderboardFilterScreen()),
        ),
      ),
      _AdminAction(
        title: '🔐 Encryption Manager',
        subtitle: 'Manage encryption keys and settings',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EncryptionManagerScreen()),
        ),
      ),
      _AdminAction(
        title: '📁 File Import/Export',
        subtitle: 'Backup or restore quiz content',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FileImportExportScreen()),
        ),
      ),
      _AdminAction(
        title: '📝 Questions List',
        subtitle: 'Add, edit, and delete questions',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuestionListScreen()),
        ),
      ),
      _AdminAction(
        title: '📝 Question Editor',
        subtitle: 'Add, edit, and delete questions',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuestionEditorScreen()),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent.shade200,
        title: Row(
          children: const [
            Icon(Icons.admin_panel_settings, color: Colors.white),
            Text('Admin Dashboard', style: TextStyle(color: Colors.grey)),
          ]
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final action = actions[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(action.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(action.subtitle),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: action.onTap,
            ),
          );
        },
      ),
    );
  }
}

class _AdminAction {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _AdminAction({required this.title, required this.subtitle, required this.onTap});
}
