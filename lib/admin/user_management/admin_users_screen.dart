import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/models/admin_user_model.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../screens/widgets/custom_alert_dialog.dart';
import '../../ui_components/cards/slide_to_expand_card.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  UserStatus? _filterStatus;
  UserRole? _filterRole;
  AgeGroup? _filterAgeGroup;
  String _sortBy = 'lastActive'; // lastActive, username, points
  List<AdminUserModel> _users = [];
  bool _isLoadingUsers = false;
  String? _usersError;

  @override
  void initState() {
    super.initState();
    _loadUsersFromBackend();
  }

  Future<void> _loadUsersFromBackend() async {
    setState(() {
      _isLoadingUsers = true;
      _usersError = null;
    });

    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final response = await serviceManager.apiService.get('/admin/users');
      final items = response['items'];
      if (items is List) {
        _users = items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(AdminUserModel.fromJson)
            .toList();
      } else {
        _users = [];
      }
    } catch (e) {
      _usersError = 'Using local sample users (backend unavailable): $e';
      _users = _getMockUsers();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = _getFilteredUsers();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(),
          if (_isLoadingUsers)
            const LinearProgressIndicator(minHeight: 2),
          if (_usersError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFFF7ED),
              child: Text(
                _usersError!,
                style: const TextStyle(color: Color(0xFF9A3412), fontSize: 12),
              ),
            ),
          _buildFilters(),
          Expanded(
            child: users.isEmpty
                ? _buildEmptyState()
                : _buildUsersList(users),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add User'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Title Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage and monitor all users',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats Cards Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Users',
                  '1,234',
                  Icons.people,
                  const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Online Now',
                  '89',
                  Icons.online_prediction,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search by username, email, or ID...',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Color(0xFF9CA3AF)),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              'Filters:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 16),
            _buildFilterChip(
              label: 'Status',
              value: _filterStatus?.name,
              onTap: () => _showStatusFilter(),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Role',
              value: _filterRole?.name,
              onTap: () => _showRoleFilter(),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Age Group',
              value: _filterAgeGroup?.name,
              onTap: () => _showAgeGroupFilter(),
            ),
            const SizedBox(width: 16),
            const Text(
              'Sort:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 16),
            _buildSortChip('Last Active', 'lastActive'),
            const SizedBox(width: 8),
            _buildSortChip('Username', 'username'),
            const SizedBox(width: 8),
            _buildSortChip('Points', 'points'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, String? value, required VoidCallback onTap}) {
    final hasValue = value != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: hasValue ? const Color(0xFF6366F1).withValues(alpha: 0.1) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasValue ? const Color(0xFF6366F1) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasValue ? '$label: $value' : label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasValue ? const Color(0xFF6366F1) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              hasValue ? Icons.close : Icons.arrow_drop_down,
              size: 18,
              color: hasValue ? const Color(0xFF6366F1) : const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList(List<AdminUserModel> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildUserCard(user),
        );
      },
    );
  }

  // Using SlideToExpandCard component
  Widget _buildUserCard(AdminUserModel user) {
    return SlideToExpandCard(
      collapsedContent: _buildCollapsedContent(user),
      expandedContent: _buildExpandedContent(user),
    );
  }

  // Collapsed view - Basic info
  Widget _buildCollapsedContent(AdminUserModel user) {
    return Row(
      children: [
        // Avatar with status indicator
        Stack(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    user.roleColor,
                    user.roleColor.withValues(alpha: 0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user.username[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: user.statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),

        // User Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (user.isVerified)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: const Icon(
                        Icons.verified,
                        color: Color(0xFF3B82F6),
                        size: 18,
                      ),
                    ),
                  if (user.isBanned)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'BANNED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Badges with Wrap to prevent overflow
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildBadge(
                    user.statusText,
                    user.statusColor,
                    Icons.circle,
                  ),
                  _buildBadge(
                    user.roleText,
                    user.roleColor,
                    user.roleIcon,
                  ),
                  _buildBadge(
                    user.ageGroupText.split(' ')[0],
                    user.ageGroupColor,
                    Icons.cake,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Quick Stats
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Color(0xFFF59E0B),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user.totalPoints.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videogame_asset,
                    color: Color(0xFF6366F1),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${user.totalGamesPlayed}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Expanded view - Detailed info
  Widget _buildExpandedContent(AdminUserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 16),

        // Detailed Stats
        Row(
          children: [
            Expanded(
              child: _buildDetailStat(
                'Win Rate',
                '${(user.winRate * 100).toInt()}%',
                Icons.trending_up,
                const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailStat(
                'Games',
                user.totalGamesPlayed.toString(),
                Icons.videogame_asset,
                const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailStat(
                'Points',
                user.totalPoints.toString(),
                Icons.emoji_events,
                const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Account Details
        _buildDetailRow('User ID', user.id),
        const SizedBox(height: 8),
        _buildDetailRow('Created', _formatDate(user.createdAt)),
        const SizedBox(height: 8),
        _buildDetailRow('Last Active', _formatTimeAgo(user.lastActive)),

        if (user.isBanned && user.banReason != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ban Reason: ${user.banReason}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.go('/admin/users/${user.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View Details'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showQuickActions(user),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.more_horiz, size: 18),
                label: const Text('Actions'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              size: 64,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No users found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters or search query',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // Mock data - replace with actual data from your backend
  List<AdminUserModel> _getFilteredUsers() {
    var users = _users;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      users = users.where((user) {
        return user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.id.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    if (_filterStatus != null) {
      users = users.where((user) => user.status == _filterStatus).toList();
    }

    // Apply role filter
    if (_filterRole != null) {
      users = users.where((user) => user.role == _filterRole).toList();
    }

    // Apply age group filter
    if (_filterAgeGroup != null) {
      users = users.where((user) => user.ageGroup == _filterAgeGroup).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'lastActive':
        users.sort((a, b) => b.lastActive.compareTo(a.lastActive));
        break;
      case 'username':
        users.sort((a, b) => a.username.compareTo(b.username));
        break;
      case 'points':
        users.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
        break;
    }

    return users;
  }

  List<AdminUserModel> _getMockUsers() {
    return [
    AdminUserModel(
      id: '1',
      username: 'john_doe',
      email: 'john@example.com',
      status: UserStatus.online,
      role: UserRole.premium,
      ageGroup: AgeGroup.adult,
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
    ageGroup: AgeGroup.teen,
    createdAt: DateTime.now().subtract(const Duration(days: 15)),
    lastActive: DateTime.now().subtract(const Duration(hours: 2)),
    totalGamesPlayed: 78,
    totalPoints: 5680,
    winRate: 0.54,
    isVerified: true,
    ),
    AdminUserModel(
    id: '3',
    username: 'bob_wilson',
    email: 'bob@example.com',
    status: UserStatus.away,
    role: UserRole.moderator,
    ageGroup: AgeGroup.adult,
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
    lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
    totalGamesPlayed: 423,
    totalPoints: 28900,
    winRate: 0.72,
    isVerified: true,
    ),
    AdminUserModel(
    id: '4',
    username: 'alice_brown',
    email: 'alice@example.com',
    status: UserStatus.online,
    role: UserRole.admin,
    ageGroup: AgeGroup.adult,
    createdAt: DateTime.now().subtract(const Duration(days: 180)),
    lastActive: DateTime.now(),
    totalGamesPlayed: 892,
    totalPoints: 56780,
    winRate: 0.85,
    isVerified: true,
    ),
    AdminUserModel(
    id: '5',
    username: 'charlie_davis',
    email: 'charlie@example.com',
    status: UserStatus.offline,
    role: UserRole.user,
    ageGroup: AgeGroup.child,
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
    lastActive: DateTime.now().subtract(const Duration(days: 1)),
    totalGamesPlayed: 23,
    totalPoints: 1450,
    winRate: 0.41,
    isVerified: false,
    ),
    AdminUserModel(
    id: '6',
    username: 'banned_user',
    email: 'banned@example.com',
      status: UserStatus.offline,
      role: UserRole.user,
      ageGroup: AgeGroup.teen,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      lastActive: DateTime.now().subtract(const Duration(days: 10)),
      totalGamesPlayed: 56,
      totalPoints: 2340,
      winRate: 0.32,
      isVerified: false,
      isBanned: true,
      banReason: 'Inappropriate behavior',
    ),
    ];
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Filter by Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...UserStatus.values.map((status) {
              return ListTile(
                leading: Icon(
                  Icons.circle,
                  color: _getStatusColor(status),
                ),
                title: Text(_getStatusText(status)),
                trailing: _filterStatus == status
                    ? const Icon(Icons.check, color: Color(0xFF6366F1))
                    : null,
                onTap: () {
                  setState(() {
                    _filterStatus = _filterStatus == status ? null : status;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  void _showRoleFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Filter by Role',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...UserRole.values.map((role) {
              return ListTile(
                leading: Icon(
                  _getRoleIcon(role),
                  color: _getRoleColor(role),
                ),
                title: Text(_getRoleText(role)),
                trailing: _filterRole == role
                    ? const Icon(Icons.check, color: Color(0xFF6366F1))
                    : null,
                onTap: () {
                  setState(() {
                    _filterRole = _filterRole == role ? null : role;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  void _showAgeGroupFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Filter by Age Group',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...AgeGroup.values.map((ageGroup) {
              return ListTile(
                leading: Icon(
                  Icons.cake,
                  color: _getAgeGroupColor(ageGroup),
                ),
                title: Text(_getAgeGroupText(ageGroup)),
                trailing: _filterAgeGroup == ageGroup
                    ? const Icon(Icons.check, color: Color(0xFF6366F1))
                    : null,
                onTap: () {
                  setState(() {
                    _filterAgeGroup = _filterAgeGroup == ageGroup ? null : ageGroup;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  void _showAddUserDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create user endpoint is not wired in this pass.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQuickActions(AdminUserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Quick Actions - ${user.username}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF6366F1)),
                title: const Text('Edit User'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditUserDialog(user);
                },
              ),
              ListTile(
                leading: Icon(
                  user.isBanned ? Icons.check_circle : Icons.block,
                  color: user.isBanned ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
                title: Text(user.isBanned ? 'Unban User' : 'Ban User'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleBanUser(user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Color(0xFF3B82F6)),
                title: const Text('Send Email'),
                onTap: () {
                  Navigator.pop(context);
                  _sendEmail(user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Color(0xFF6B7280)),
                title: const Text('View Activity Log'),
                onTap: () {
                  Navigator.pop(context);
                  _viewActivityLog(user);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                title: const Text(
                  'Delete User',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteUser(user);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  void _toggleBanUser(AdminUserModel user) {
    showCustomAlertDialog(
      context: context,
      title: user.isBanned ? 'Unban User' : 'Ban User',
      message: user.isBanned
          ? 'Are you sure you want to unban ${user.username}?'
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
            await serviceManager.apiService.post(
              '/admin/users/${user.id}/ban',
              body: {'reason': 'Admin action'},
            );
          }
          await _loadUsersFromBackend();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                user.isBanned
                    ? '${user.username} has been unbanned'
                    : '${user.username} has been banned',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update ban state: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      },
    );
  }
  void _deleteUser(AdminUserModel user) {
    showCustomAlertDialog(
      context: context,
      title: 'Delete User',
      message: 'Are you sure you want to permanently delete ${user.username}? This action cannot be undone.',
      type: AlertType.delete,
      confirmText: 'Delete User',
      cancelText: 'Cancel',
      onConfirm: () async {
        try {
          final serviceManager = ref.read(serviceManagerProvider);
          await serviceManager.apiService.delete('/admin/users/${user.id}');
          await _loadUsersFromBackend();
          if (!mounted) return;
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
            SnackBar(
              content: Text('Failed to delete user: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFFEF4444),
            ),
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
  void _viewActivityLog(AdminUserModel user) {
    _loadActivityLog(user);
  }

  Future<void> _loadActivityLog(AdminUserModel user) async {
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final response = await serviceManager.apiService.get('/admin/users/${user.id}/activity');
      final items = response['items'];
      final logs = items is List
          ? items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      _showActivityLogDialog(user, logs);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load activity log: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showActivityLogDialog(AdminUserModel user, List<Map<String, dynamic>> logs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Activity Log • ${user.username}'),
        content: SizedBox(
          width: 500,
          child: logs.isEmpty
              ? const Text('No activity records found.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (_, i) {
                    final log = logs[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log['type']?.toString() ?? 'UNKNOWN',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(log['description']?.toString() ?? '-'),
                        const SizedBox(height: 4),
                        Text(log['createdAt']?.toString() ?? '-',
                            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(AdminUserModel user) {
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
                    .map((r) => DropdownMenuItem(value: r, child: Text(_getRoleText(r))))
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
                  await _loadUsersFromBackend();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User updated'), behavior: SnackBarBehavior.floating),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update user: $e')),
                  );
                }
              },
              child: const Text('Save'),
            )
          ],
        ),
      ),
    );
  }

// Helper methods for filters
  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return const Color(0xFF10B981);
      case UserStatus.offline:
        return const Color(0xFF6B7280);
      case UserStatus.away:
        return const Color(0xFFF59E0B);
      case UserStatus.busy:
        return const Color(0xFFEF4444);
    }
  }
  String _getStatusText(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return 'Online';
      case UserStatus.offline:
        return 'Offline';
      case UserStatus.away:
        return 'Away';
      case UserStatus.busy:
        return 'Busy';
    }
  }
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.user:
        return const Color(0xFF6B7280);
      case UserRole.premium:
        return const Color(0xFFFFD700);
      case UserRole.moderator:
        return const Color(0xFF3B82F6);
      case UserRole.admin:
        return const Color(0xFFEF4444);
    }
  }
  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'User';
      case UserRole.premium:
        return 'Premium';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.admin:
        return 'Admin';
    }
  }
  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.user:
        return Icons.person;
      case UserRole.premium:
        return Icons.stars;
      case UserRole.moderator:
        return Icons.shield;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }
  Color _getAgeGroupColor(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return const Color(0xFF8B5CF6);
      case AgeGroup.teen:
        return const Color(0xFF3B82F6);
      case AgeGroup.adult:
        return const Color(0xFF10B981);
      case AgeGroup.senior:
        return const Color(0xFFF59E0B);
    }
  }
  String _getAgeGroupText(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'Child (6-12)';
      case AgeGroup.teen:
        return 'Teen (13-17)';
      case AgeGroup.adult:
        return 'Adult (18-64)';
      case AgeGroup.senior:
        return 'Senior (65+)';
    }
  }

  String _formatDate(DateTime date) {
    return 'date.day/${date.day}/date.day/${date.month}/${date.year}';
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
}
