import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/social/friend_request_dto.dart';
import '../../../core/services/api_service.dart';
import '../../../game/providers/friends_providers.dart';
import '../../../game/providers/profile_providers.dart'
    hide currentUserIdProvider;
import '../../messages/widgets/safe_text.dart';

class AddFriendDialog extends ConsumerStatefulWidget {
  const AddFriendDialog({super.key});

  @override
  ConsumerState<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends ConsumerState<AddFriendDialog> {
  bool _isMutating = false;

  @override
  Widget build(BuildContext context) {
    final incomingRequestsAsync = ref.watch(incomingFriendRequestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF36393F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF36393F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const SafeText(
          'Add Friends',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildShareOptions(),
          _buildQuickActions(),
          Expanded(
            child: incomingRequestsAsync.when(
              data: (page) => _buildIncomingRequests(page.items),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildShareButton(Icons.share, 'Share Invite', Colors.grey),
            const SizedBox(width: 8),
            _buildShareButton(Icons.link, 'Copy Link', Colors.grey),
            const SizedBox(width: 8),
            _buildShareButton(Icons.qr_code, 'QR Code', Colors.grey),
            const SizedBox(width: 8),
            _buildShareButton(Icons.message, 'Messages', Colors.green),
            const SizedBox(width: 8),
            _buildShareButton(Icons.email, 'Email', Colors.blue),
            const SizedBox(width: 8),
            _buildShareButton(Icons.facebook, 'Messenger', Colors.blue),
            const SizedBox(width: 8),
            _buildShareButton(Icons.mail, 'Gmail', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: SafeText(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF40444B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF5865F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.people, color: Colors.white, size: 20),
            ),
            title: const SafeText(
              'Find Your Friends',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {},
          ),
          const Divider(color: Color(0xFF36393F), height: 1),
          ListTile(
            leading: const Icon(Icons.alternate_email,
                color: Colors.white70, size: 24),
            title: const SafeText(
              'Add by Username',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white70),
            onTap: () {
              Navigator.pop(context);
              context.push('/friends/add-username');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequests(List<FriendRequestDto> requests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: SafeText(
            'Incoming Friend Requests',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (requests.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline,
                      color: Color(0xFF72767D), size: 48),
                  SizedBox(height: 12),
                  SafeText(
                    'No incoming friend requests',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return _buildFriendRequestTile(request);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFriendRequestTile(FriendRequestDto request) {
    final displayName =
        request.senderDisplayName ?? request.senderUsername ?? 'Unknown';
    final username =
        request.senderUsername ?? request.senderDisplayName ?? 'unknown';
    final avatarChar = _avatarChar(displayName);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF40444B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF5865F2),
            child: SafeText(
              avatarChar,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SafeText(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                SafeText(
                  username,
                  style: const TextStyle(
                    color: Color(0xFFB9BBBE),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: _isMutating ? null : () => _declineRequest(request),
                icon: const Icon(Icons.close, color: Color(0xFF72767D)),
                tooltip: 'Decline request',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
              ),
              IconButton(
                onPressed: _isMutating ? null : () => _acceptRequest(request),
                icon: const Icon(Icons.check, color: Color(0xFF3BA55C)),
                tooltip: 'Accept request',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final message = error is ApiRequestException
        ? error.message
        : 'Could not load friend requests right now.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: Color(0xFF72767D), size: 48),
            const SizedBox(height: 12),
            const SafeText(
              'Friend requests are unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SafeText(
              message,
              style: const TextStyle(color: Color(0xFFB9BBBE), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(incomingFriendRequestsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptRequest(FriendRequestDto request) async {
    await _mutateRequest(
      action: () => ref
          .read(backendProfileSocialServiceProvider)
          .acceptFriendRequest(request.requestId),
      successMessage: 'Friend request accepted!',
      successColor: const Color(0xFF3BA55C),
    );
  }

  Future<void> _declineRequest(FriendRequestDto request) async {
    await _mutateRequest(
      action: () => ref
          .read(backendProfileSocialServiceProvider)
          .declineFriendRequest(request.requestId),
      successMessage: 'Friend request declined',
      successColor: const Color(0xFF72767D),
    );
  }

  Future<void> _mutateRequest({
    required Future<void> Function() action,
    required String successMessage,
    required Color successColor,
  }) async {
    setState(() {
      _isMutating = true;
    });

    try {
      await action();
      ref.invalidate(incomingFriendRequestsProvider);
      ref.invalidate(friendsListProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SafeText(successMessage),
          backgroundColor: successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } on ApiRequestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SafeText(e.message),
          backgroundColor: const Color(0xFFED4245),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: SafeText('Something went wrong. Please try again.'),
          backgroundColor: Color(0xFFED4245),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  String _avatarChar(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed[0].toUpperCase();
  }
}
