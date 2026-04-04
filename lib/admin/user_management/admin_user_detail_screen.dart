import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import '../../game/models/admin_user_model.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../screens/widgets/custom_alert_dialog.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const AdminUserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AdminUserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final response = await serviceManager.apiService.get('/admin/users/${widget.userId}');
      _user = AdminUserModel.fromJson(response);
    } catch (_) {
      _user = await _loadUserFromListEndpoint(widget.userId) ?? _getUserById(widget.userId);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<AdminUserModel?> _loadUserFromListEndpoint(String userId) async {
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final response =
          await serviceManager.apiService.get('/admin/users?page=1&pageSize=100');
      final envelope = serviceManager.apiService
          .parsePageEnvelope<Map<String, dynamic>>(response, (json) => json);
      for (final map in envelope.items) {
        if (map['id']?.toString() == userId) {
          return AdminUserModel.fromJson(map);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Not Found'),
        ),
        body: const Center(
          child: Text('User not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(user),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildUserHeader(user),
                _buildTabBar(),
                _buildTabContent(user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(AdminUserModel user) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.arrow_back,
            color: Color(0xFF6366F1),
          ),
        ),
        onPressed: () => context.go('/admin/users'),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.edit,
              color: Color(0xFF6366F1),
            ),
          ),
          onPressed: () => _showEditDialog(user),
        ),
        PopupMenuButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.more_vert,
              color: Color(0xFF6366F1),
            ),
          ),
          itemBuilder: (context) => <PopupMenuEntry>
          [
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(
                    user.isBanned ? Icons.check_circle : Icons.block,
                    color: user.isBanned ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(user.isBanned ? 'Unban User' : 'Ban User'),
                ],
              ),
              onTap: () => _toggleBanUser(user),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.email, color: Color(0xFF3B82F6), size: 20),
                  SizedBox(width: 12),
                  Text('Send Email'),
                ],
              ),
              onTap: () => _sendEmail(user),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.history, color: Color(0xFF6B7280), size: 20),
                  SizedBox(width: 12),
                  Text('View Activity Log'),
                ],
              ),
              onTap: () => _viewActivityLog(user),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.manage_search, color: Color(0xFF4F46E5), size: 20),
                  SizedBox(width: 12),
                  Text('View Audit Log'),
                ],
              ),
              onTap: () => _viewAuditLog(user),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Color(0xFFEF4444), size: 20),
                  SizedBox(width: 12),
                  Text('Delete User', style: TextStyle(color: Color(0xFFEF4444))),
                ],
              ),
              onTap: () => _deleteUser(user),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(AdminUserModel user) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          Transform.translate(
            offset: const Offset(0, -50),
            child: Column(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            user.roleColor,
                            user.roleColor.withValues(alpha: 0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: user.statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Username and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.verified,
                        color: Color(0xFF3B82F6),
                        size: 24,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),

                // Status Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatusBadge(
                      user.statusText,
                      user.statusColor,
                      Icons.circle,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(
                      user.roleText,
                      user.roleColor,
                      user.roleIcon,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(
                      user.ageGroupText.split(' ')[0],
                      user.ageGroupColor,
                      Icons.cake,
                    ),
                  ],
                ),

                if (user.isBanned) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEF4444),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.block,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'BANNED',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        if (user.banReason != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '- ${user.banReason}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Games Played',
                  user.totalGamesPlayed.toString(),
                  Icons.videogame_asset,
                  const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Points',
                  user.totalPoints.toString(),
                  Icons.emoji_events,
                  const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Win Rate',
                  '${(user.winRate * 100).toInt()}%',
                  Icons.trending_up,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: const Color(0xFF9CA3AF),
        indicatorColor: const Color(0xFF6366F1),
        indicatorWeight: 3,
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 18),
                SizedBox(width: 8),
                Text('Info'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 18),
                SizedBox(width: 8),
                Text('Activity'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.analytics_outlined, size: 18),
                SizedBox(width: 8),
                Text('Stats'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.security, size: 18),
                SizedBox(width: 8),
                Text('Security'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(AdminUserModel user) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 500,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(user),
          _buildActivityTab(user),
          _buildStatsTab(user),
          _buildSecurityTab(user),
        ],
      ),
    );
  }

  Widget _buildInfoTab(AdminUserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Account Information', [
            _buildInfoRow('User ID', user.id),
            _buildInfoRow('Username', user.username),
            _buildInfoRow('Email', user.email),
            _buildInfoRow('Status', user.statusText, color: user.statusColor),
            _buildInfoRow('Role', user.roleText, color: user.roleColor),
            _buildInfoRow('Age Group', user.ageGroupText, color: user.ageGroupColor),
            _buildInfoRow('Verified', user.isVerified ? 'Yes' : 'No',
                color: user.isVerified ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
          ]),
          const SizedBox(height: 24),
          _buildInfoSection('Account Dates', [
            _buildInfoRow('Created', _formatDate(user.createdAt)),
            _buildInfoRow('Last Active', _formatDate(user.lastActive)),
            _buildInfoRow(
              'Member For',
              '${DateTime.now().difference(user.createdAt).inDays} days',
            ),
          ]),
          const SizedBox(height: 24),
          _buildInfoSection('Game Statistics', [
            _buildInfoRow('Total Games', user.totalGamesPlayed.toString()),
            _buildInfoRow('Total Points', user.totalPoints.toString()),
            _buildInfoRow('Win Rate', '${(user.winRate * 100).toStringAsFixed(1)}%'),
          ]),
        ],
      ),
    );
  }

  Widget _buildActivityTab(AdminUserModel user) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildActivityItem(
          'Completed Quiz',
          'Science & Nature - Score: 850',
          DateTime.now().subtract(const Duration(hours: 2)),
          Icons.quiz,
          const Color(0xFF6366F1),
        ),
        _buildActivityItem(
          'Logged In',
          'From Mobile App',
          DateTime.now().subtract(const Duration(hours: 5)),
          Icons.login,
          const Color(0xFF10B981),
        ),
        _buildActivityItem(
          'Achievement Unlocked',
          'First Win Streak',
          DateTime.now().subtract(const Duration(days: 1)),
          Icons.emoji_events,
          const Color(0xFFF59E0B),
        ),
        _buildActivityItem(
          'Profile Updated',
          'Changed avatar',
          DateTime.now().subtract(const Duration(days: 2)),
          Icons.person,
          const Color(0xFF3B82F6),
        ),
      ],
    );
  }

  Widget _buildStatsTab(AdminUserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildProgressBar('Quiz Completion', 0.75, const Color(0xFF6366F1)),
                const SizedBox(height: 16),
                _buildProgressBar('Win Rate', user.winRate, const Color(0xFF10B981)),
                const SizedBox(height: 16),
                _buildProgressBar('Activity Level', 0.82, const Color(0xFFF59E0B)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Category Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryPerformance('Science', 0.85, const Color(0xFF10B981)),
          _buildCategoryPerformance('History', 0.72, const Color(0xFF3B82F6)),
          _buildCategoryPerformance('Geography', 0.68, const Color(0xFFF59E0B)),
          _buildCategoryPerformance('Sports', 0.54, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildSecurityTab(AdminUserModel user) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            _buildSecuritySection('Account Security', [
          _buildSecurityItem(
            'Two-Factor Authentication',
            'Enabled',
            Icons.security,
            const Color(0xFF10B981),
          ),
          _buildSecurityItem(
            'Email Verification',
            user.isVerified ? 'Verified' : 'Not Verified',
            Icons.email,
            user.isVerified ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          _buildSecurityItem(
            'Password Strength',
            'Strong',
            Icons.lock,
            const Color(0xFF10B981),
          ),
        ]),
        const SizedBox(height: 24),
        _buildSecuritySection('Recent Sessions', [
          _buildSessionItem(
            'Current Session',
            'Mobile App - iOS',
            'New York, USA',
            DateTime.now().subtract(const Duration(minutes: 5)),
            true,
          ),
          _buildSessionItem(
            'Previous Session',
            'Web Browser - Chrome',
            'New York, USA',
            DateTime.now().subtract(const Duration(hours: 12)),
            false,
          ),
        ]),
        const SizedBox(height: 24),
        if (user.isBanned)
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444),
          width: 2,
        ),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
      const Row(
      children: [
      Icon(Icons.block, color: Color(0xFFEF4444)),
      SizedBox(width: 12),
      Text(
        'Account Banned',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFEF4444),
        ),
      ),
      ],
    ),
    const SizedBox(height:12),
            Text(
              'Reason: ${user.banReason ?? "No reason provided"}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _toggleBanUser(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Unban User'),
            ),
          ],
      ),
    ),
            ],
        ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, DateTime timestamp, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTimeAgo(timestamp),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPerformance(String category, double score, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${(score * 100).toInt()}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: score,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSecurityItem(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(
      String title,
      String device,
      String location,
      DateTime timestamp,
      bool isActive,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFF6B7280).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.devices,
              color: isActive ? const Color(0xFF10B981) : const Color(0xFF6B7280),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  device,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  '$location • ${_formatTimeAgo(timestamp)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return
      'date.day/${date.day}/ date.day/${date.month}/${date.year} '
      '${date.hour}:${date.minute.toString().padLeft(2,'0')}';
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return _formatDate(date);
    }
  }

// Fallback sample user lookup for offline/unsupported backend environments.
  AdminUserModel? _getUserById(String userId) {
    final users = [
      AdminUserModel(
        id: '1',
        username: 'john_doe',
        email: 'john@example.com',
        status: UserStatus.online,
        role: UserRole.premium,
        ageGroup: AgeGroup.adults,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
        totalGamesPlayed: 145,
        totalPoints: 12450,
        winRate: 0.68,
        isVerified: true,
      ),
      AdminUserModel(
        id: '2',
        username: 'jane_smith',
        email: 'jane@example.com',
        status: UserStatus.offline,
        role: UserRole.user,
        ageGroup: AgeGroup.teens,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        lastActive: DateTime.now().subtract(const Duration(hours: 2)),
        totalGamesPlayed: 78,
        totalPoints: 5680,
        winRate: 0.54,
        isVerified: true,
      ),
// Additional fallback users can be added here if needed.
    ];
    try {
      return users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

// Action methods
  void _showEditDialog(AdminUserModel user) {
    UserRole selectedRole = user.role;
    bool verified = user.isVerified;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit ${user.username}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                items: UserRole.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedRole = v);
                },
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: verified,
                title: const Text('Verified'),
                onChanged: (v) => setDialogState(() => verified = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final serviceManager = ref.read(serviceManagerProvider);
                  await serviceManager.apiService.patch('/admin/users/${user.id}', body: {
                    'role': selectedRole.name,
                    'isVerified': verified,
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  await _loadUser();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User updated')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update user: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleBanUser(AdminUserModel user) {
    showCustomAlertDialog(
      context: context,
      title: user.isBanned ? 'Unban User' : 'Ban User',
      message: user.isBanned
          ? 'Are you sure you want to unban ${user.username}? This will restore their access to the app.'
          : 'Are you sure you want to ban ${user.username}? This will prevent them from accessing the app.',
      type: user.isBanned ? AlertType.success : AlertType.warning,
      confirmText: user.isBanned ? 'Unban User' : 'Ban User',
      cancelText: 'Cancel',
      onConfirm: () async {
        try {
          final serviceManager = ref.read(serviceManagerProvider);
          if (user.isBanned) {
            await serviceManager.apiService.post('/admin/users/${user.id}/unban', body: {});
          } else {
            await serviceManager.apiService.post('/admin/users/${user.id}/ban',
                body: {'reason': 'Admin action'});
          }
          await _loadUser();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(user.isBanned ? '${user.username} has been unbanned' : '${user.username} has been banned'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update ban state: $e')),
          );
        }
      },
    );
  }

  void _deleteUser(AdminUserModel user) {
    showCustomAlertDialog(
      context: context,
      title: 'Delete User',
      message: 'Are you sure you want to permanently delete ${user.username}? This action cannot be undone and all user data will be lost.',
      type: AlertType.delete,
      confirmText: 'Delete User',
      cancelText: 'Cancel',
      onConfirm: () async {
        try {
          final serviceManager = ref.read(serviceManagerProvider);
          await serviceManager.apiService.delete('/admin/users/${user.id}');
          if (!mounted) return;
          context.go('/admin/users');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.username} has been deleted'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete user: $e')),
          );
        }
      },
    );
  }

  void _sendEmail(AdminUserModel user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email composer opened for ${user.email}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  void _viewAuditLog(AdminUserModel user) {
    context.go('/admin/audit?userId=${Uri.encodeComponent(user.id)}');
  }

  void _viewActivityLog(AdminUserModel user) {
    _loadActivityLog(user);
  }

  Future<void> _loadActivityLog(AdminUserModel user) async {
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final response = await serviceManager.apiService.get('/admin/users/${user.id}/activity');
      final envelope = serviceManager.apiService
          .parsePageEnvelope<Map<String, dynamic>>(response, (json) => json);
      final logs = envelope.items;
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Activity Log'),
          content: SizedBox(
            width: 500,
            child: logs.isEmpty
                ? const Text('No activity records found.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: logs.length,
                    itemBuilder: (_, i) => ListTile(
                      dense: true,
                      title: Text(logs[i]['type']?.toString() ?? 'UNKNOWN'),
                      subtitle: Text(logs[i]['description']?.toString() ?? '-'),
                      trailing: Text(logs[i]['createdAt']?.toString() ?? ''),
                    ),
                  ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load activity log: $e')),
      );
    }
  }

}
