import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../game/models/referral_models.dart';
import '../game/providers/riverpod_providers.dart';
import '../game/services/referral_invite_service.dart';

/// Invite Log Screen - Shows all referral invites with status tracking
class InviteLogScreen extends ConsumerStatefulWidget {
  const InviteLogScreen({super.key});

  @override
  ConsumerState<InviteLogScreen> createState() => _InviteLogScreenState();
}

class _InviteLogScreenState extends ConsumerState<InviteLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterStatus = 'all'; // all, pending, redeemed, expired

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the service and stats
    final serviceAsync = ref.watch(asyncReferralInviteServiceProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      body: serviceAsync.when(
        data: (service) => _buildBody(service),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading invites',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final serviceAsync = ref.watch(asyncReferralInviteServiceProvider);

    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF6366F1),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      title: const Text(
        'Invite Log',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            serviceAsync.whenData((service) => service.syncUnsyncedInvites());
            setState(() {});
          },
          tooltip: 'Refresh',
        ),
      ],
      bottom: serviceAsync.when(
        data: (service) {
          final stats = service.getStats();
          return _buildTabBar(stats);
        },
        loading: () => _buildTabBar({'total': 0, 'pending': 0, 'redeemed': 0, 'expired': 0}),
        error: (_, __) => _buildTabBar({'total': 0, 'pending': 0, 'redeemed': 0, 'expired': 0}),
      ),
    );
  }

  PreferredSizeWidget _buildTabBar(Map<String, int> stats) {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.white,
      indicatorWeight: 3,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      onTap: (index) {
        setState(() {
          _filterStatus = ['all', 'pending', 'redeemed', 'expired'][index];
        });
      },
      tabs: [
        _buildTab('All', stats['total'] ?? 0),
        _buildTab('Pending', stats['pending'] ?? 0),
        _buildTab('Redeemed', stats['redeemed'] ?? 0),
        _buildTab('Expired', stats['expired'] ?? 0),
      ],
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ReferralInviteService service) {
    List<ReferralInvite> invites;

    switch (_filterStatus) {
      case 'pending':
        invites = service.getPendingInvites();
        break;
      case 'redeemed':
        invites = service.getRedeemedInvites();
        break;
      case 'expired':
        invites = service.getExpiredInvites();
        break;
      default:
        invites = service.getInvites();
    }

    if (invites.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await service.syncUnsyncedInvites();
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invites.length,
        itemBuilder: (context, index) {
          return _buildInviteCard(invites[index], service);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_filterStatus) {
      case 'pending':
        message = 'No pending invites';
        icon = Icons.schedule;
        break;
      case 'redeemed':
        message = 'No redeemed invites yet';
        icon = Icons.check_circle_outline;
        break;
      case 'expired':
        message = 'No expired invites';
        icon = Icons.timer_off;
        break;
      default:
        message = 'No invites created yet';
        icon = Icons.inbox;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(ReferralInvite invite, ReferralInviteService service) {
    final status = invite.status;
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    switch (status) {
      case InviteStatus.redeemed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Redeemed';
        break;
      case InviteStatus.expired:
        statusColor = Colors.red;
        statusIcon = Icons.timer_off;
        statusText = 'Expired';
        break;
      case InviteStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Pending';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _showInviteDetails(invite, service),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invite.referralCode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created ${_formatDate(invite.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (invite.inviteeName != null) ...[
                _buildInfoRow(
                  Icons.person_outline,
                  'Invited: ${invite.inviteeName}',
                ),
                const SizedBox(height: 8),
              ],
              if (status == InviteStatus.pending) ...[
                _buildInfoRow(
                  Icons.timer,
                  'Expires in ${invite.daysUntilExpiration} days',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _getExpirationProgress(invite),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(invite),
                  ),
                ),
              ],
              if (status == InviteStatus.redeemed && invite.redeemedAt != null) ...[
                _buildInfoRow(
                  Icons.check_circle_outline,
                  'Redeemed ${_formatDate(invite.redeemedAt!)}',
                ),
                if (invite.metadata?['redeemerName'] != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.person,
                    'By: ${invite.metadata!['redeemerName']}',
                  ),
                ],
              ],
              if (status == InviteStatus.expired) ...[
                _buildInfoRow(
                  Icons.event_busy,
                  'Expired ${_formatDate(invite.expiresAt)}',
                ),
              ],
              if (!invite.isSynced) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Not synced to server',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  double _getExpirationProgress(ReferralInvite invite) {
    final total = invite.expiresAt.difference(invite.createdAt).inSeconds;
    final remaining = invite.expiresAt.difference(DateTime.now()).inSeconds;
    return (total - remaining) / total;
  }

  Color _getProgressColor(ReferralInvite invite) {
    final daysLeft = invite.daysUntilExpiration;
    if (daysLeft <= 1) return Colors.red;
    if (daysLeft <= 3) return Colors.orange;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  void _showInviteDetails(ReferralInvite invite, ReferralInviteService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Invite Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Referral Code', invite.referralCode),
                _buildDetailRow('Status', invite.status.name.toUpperCase()),
                _buildDetailRow('Created', DateFormat('MMM d, y h:mm a').format(invite.createdAt)),
                _buildDetailRow('Expires', DateFormat('MMM d, y h:mm a').format(invite.expiresAt)),
                if (invite.inviteeName != null)
                  _buildDetailRow('Invited', invite.inviteeName!),
                if (invite.inviteeEmail != null)
                  _buildDetailRow('Email', invite.inviteeEmail!),
                if (invite.redeemedAt != null)
                  _buildDetailRow('Redeemed', DateFormat('MMM d, y h:mm a').format(invite.redeemedAt!)),
                if (invite.redeemedBy != null)
                  _buildDetailRow('Redeemed By', invite.redeemedBy!),
                _buildDetailRow('Synced', invite.isSynced ? 'Yes' : 'No'),
                if (invite.serverId != null)
                  _buildDetailRow('Server ID', invite.serverId!),
                const SizedBox(height: 24),
                if (invite.isPending)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await service.deleteInvite(invite.id);
                        if (context.mounted) {
                          context.pop();
                          setState(() {});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Cancel Invite'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}