import 'package:flutter/material.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _autoPlayVideos = false;
  bool _showImagesInQuestions = true;
  bool _enableHapticFeedback = true;
  bool _autoAdvanceQuestions = false;
  String _selectedLanguage = 'English';
  String _selectedDifficulty = 'Adaptive';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: _buildAppBar(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Game Preferences
          _buildSection(
            'Game Preferences',
            Icons.sports_esports_rounded,
            [
              _buildSwitchTile(
                icon: Icons.image_rounded,
                title: 'Questions with Images',
                subtitle: 'Show visual content in trivia questions',
                value: _showImagesInQuestions,
                onChanged: (value) => setState(() => _showImagesInQuestions = value),
                color: const Color(0xFFF59E0B),
              ),
              _buildSwitchTile(
                icon: Icons.fast_forward_rounded,
                title: 'Auto-Advance Questions',
                subtitle: 'Move to next question automatically',
                value: _autoAdvanceQuestions,
                onChanged: (value) => setState(() => _autoAdvanceQuestions = value),
                color: const Color(0xFF06B6D4),
              ),
              _buildNavigationTile(
                icon: Icons.speed_rounded,
                title: 'Default Difficulty',
                subtitle: _selectedDifficulty,
                color: const Color(0xFF8B5CF6),
                onTap: () => _showDifficultyDialog(),
              ),
            ],
          ),

          // Accessibility
          _buildSection(
            'Accessibility',
            Icons.accessibility_new_rounded,
            [
              _buildSwitchTile(
                icon: Icons.vibration_rounded,
                title: 'Haptic Feedback',
                subtitle: 'Vibrate on interactions',
                value: _enableHapticFeedback,
                onChanged: (value) => setState(() => _enableHapticFeedback = value),
                color: const Color(0xFF10B981),
              ),
              _buildNavigationTile(
                icon: Icons.text_fields_rounded,
                title: 'Text Size',
                subtitle: 'Adjust font size',
                color: const Color(0xFF6366F1),
                onTap: () {},
              ),
              _buildNavigationTile(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: _selectedLanguage,
                color: const Color(0xFFEF4444),
                onTap: () => _showLanguageDialog(),
              ),
            ],
          ),

          // Media Preferences
          _buildSection(
            'Media',
            Icons.perm_media_rounded,
            [
              _buildSwitchTile(
                icon: Icons.play_circle_rounded,
                title: 'Auto-Play Videos',
                subtitle: 'Automatically play video content',
                value: _autoPlayVideos,
                onChanged: (value) => setState(() => _autoPlayVideos = value),
                color: const Color(0xFFEC4899),
              ),
              _buildNavigationTile(
                icon: Icons.data_usage_rounded,
                title: 'Data Usage',
                subtitle: 'Manage cellular data preferences',
                color: const Color(0xFF06B6D4),
                onTap: () {},
              ),
            ],
          ),

          // Newsletter (from your original preferences)
          _buildSection(
            'Communication',
            Icons.mail_rounded,
            [
              _buildNavigationTile(
                icon: Icons.newspaper_rounded,
                title: 'Newsletter',
                subtitle: 'Stay updated with news and tips',
                color: const Color(0xFF06B6D4),
                onTap: () {},
              ),
            ],
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      title: const Text(
        'Preferences',
        style: TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData sectionIcon, List<Widget> items) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withValues(alpha: 0.08),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF64748B).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(title, sectionIcon),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.1),
            const Color(0xFF8B5CF6).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF64748B).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF64748B).withValues(alpha: 0.8),
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: color,
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF64748B).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF64748B).withValues(alpha: 0.8),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: const Color(0xFF64748B).withValues(alpha: 0.5),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English'),
            _buildLanguageOption('Spanish'),
            _buildLanguageOption('French'),
            _buildLanguageOption('German'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    return RadioListTile<String>(
      title: Text(language),
      value: language,
      groupValue: _selectedLanguage,
      onChanged: (value) {
        setState(() => _selectedLanguage = value!);
        Navigator.pop(context);
      },
    );
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Default Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyOption('Easy'),
            _buildDifficultyOption('Medium'),
            _buildDifficultyOption('Hard'),
            _buildDifficultyOption('Adaptive'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyOption(String difficulty) {
    return RadioListTile<String>(
      title: Text(difficulty),
      subtitle: difficulty == 'Adaptive'
          ? const Text('Adjusts based on your performance')
          : null,
      value: difficulty,
      groupValue: _selectedDifficulty,
      onChanged: (value) {
        setState(() => _selectedDifficulty = value!);
        Navigator.pop(context);
      },
    );
  }
}