import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart'
    hide analyticsServiceProvider;
import '../../game/analytics/providers/analytics_providers.dart';
import '../../game/models/referral_models.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logScreenView();
    });
  }

  void _logScreenView() {
    try {
      ref.read(analyticsServiceProvider).logEvent('screen_view', {
        'screen_name': 'invite_screen',
        'screen_class': 'InviteScreen',
      });
    } catch (e) {
      LogManager.debug('Analytics error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Watch both providers
    final referralAsync = ref.watch(userReferralCodeProvider);
    final serviceAsync = ref.watch(asyncReferralServiceProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, theme),
      // Use a combined when or handle them sequentially
      body: referralAsync.when(
        data: (referralCode) => serviceAsync.when(
          data: (service) {
            final link = service.getReferralLink(referralCode.code);
            final qrData = service.getQRCodeData(referralCode);
            return _buildContent(context, theme, referralCode, link, qrData);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              _buildContentFallback(context, theme, referralCode),
        ),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your referral code...'),
            ],
          ),
        ),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: _buildNavButton(
        icon: Icons.arrow_back_rounded,
        onPressed: () => context.pop(),
        theme: theme,
      ),
      title: Text(
        'Invite Friends',
        style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
        _buildNavButton(
          icon: Icons.history_rounded,
          onPressed: () => context.push('/invite-log'),
          theme: theme,
        ),
        const SizedBox(width: 8),
        _buildNavButton(
          icon: Icons.qr_code_scanner_rounded,
          onPressed: () => _openQrScanner(context),
          theme: theme,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNavButton(
      {required IconData icon,
      required VoidCallback onPressed,
      required ThemeData theme}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: theme.primaryColor, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ReferralCode referralCode,
    String referralLink,
    String qrCodeData,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRewardBanner(),
          const SizedBox(height: 32),
          _buildInfoCard(
            title: 'YOUR REFERRAL CODE',
            child: _buildCodeRow(context, referralCode.code, theme),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(
            title: 'YOUR QR CODE',
            child: Center(child: _buildQRCode(qrCodeData)),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(
            title: 'YOUR REFERRAL LINK',
            child: _buildLinkRow(context, referralLink, theme),
          ),
          const SizedBox(height: 32),
          _buildShareButton(referralCode.code, referralLink),
          const SizedBox(height: 24),
          _buildHowItWorks(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // --- Logic Methods ---

  void _shareInvite(String code, String link) async {
    final String shareMessage = 'Join Synaptix and compete with me!\n\n'
        'Use my referral code: $code\n\n'
        'Or sign up directly:\n$link\n\n'
        'We both get bonus rewards when you join!';

    try {
      // Correct share_plus 10.1.0 syntax
      final result = await Share.share(
        shareMessage,
        subject: 'Join me on Synaptix!',
      );

      if (!mounted) return;

      if (result.status == ShareResultStatus.success) {
        _showSnackBar('Shared successfully!', Colors.green);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Could not share: $e', Colors.red);
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Copied to clipboard', Colors.green);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- Sub-widgets extracted for cleanliness ---

  Widget _buildRewardBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF9333EA), Color(0xFF7C3AED)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF9333EA).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard_rounded,
                  color: Color(0xFFFFD700), size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Invite friends &',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    Text('get rewarded!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Enjoy rewards through our points system when friends join!',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeRow(BuildContext context, String code, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(code,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
          IconButton(
            icon: Icon(Icons.copy_rounded, color: theme.primaryColor),
            onPressed: () => _copyToClipboard(context, code),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(String code, String link) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _shareInvite(code, link),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        icon: const Icon(Icons.share_rounded),
        label: const Text('SHARE INVITE',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // (Note: Keep your existing _buildQRCode and _buildInfoCard helpers here)
  // ... rest of your UI helper methods ...

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          TextButton(
            onPressed: () => ref.invalidate(userReferralCodeProvider),
            child: const Text('Retry'),
          )
        ],
      ),
    );
  }

  void _openQrScanner(BuildContext context) async {
    final result = await context.push<String>('/qr-scanner');
    if (result != null && mounted) {
      _showSnackBar('Scanned: $result', Colors.green);
    }
  }

  Widget _buildContentFallback(
      BuildContext context, ThemeData theme, ReferralCode referralCode) {
    final link = 'https://synaptix.app/invite?code=${referralCode.code}';
    return _buildContent(context, theme, referralCode, link, link);
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(20)),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ],
    );
  }

  Widget _buildQRCode(String data) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: 180.0,
      gapless: false,
    );
  }

  Widget _buildLinkRow(BuildContext context, String link, ThemeData theme) {
    return Row(
      children: [
        Expanded(
            child: Text(link,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]))),
        IconButton(
            icon: Icon(Icons.copy, size: 20, color: theme.primaryColor),
            onPressed: () => _copyToClipboard(context, link)),
      ],
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.blue[50], borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text('How it works',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 10),
          _stepRow(Icons.share, 'Share your unique code'),
          _stepRow(Icons.how_to_reg, 'Friend signs up with code'),
          _stepRow(Icons.card_giftcard, 'Both receive rewards!'),
        ],
      ),
    );
  }

  Widget _stepRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: Colors.blue[900])),
        ],
      ),
    );
  }
}
