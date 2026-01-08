import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import '../../game/models/referral_models.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  @override
  void initState() {
    super.initState();

    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final analytics = ref.read(analyticsServiceProvider);
        analytics.logEvent('screen_view', {
          'screen_name': 'invite_screen',
          'screen_class': 'InviteScreen',
        });
      } catch (e) {
        debugPrint('Analytics error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final referralAsync = ref.watch(userReferralCodeProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Container(
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: theme.primaryColor),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          'Invite Friends',
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        // NEW: Action buttons
        actions: [
          // History/Log button
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.history_rounded,
                  color: theme.primaryColor,
                ),
                tooltip: 'Invite History',
                onPressed: () {
                  // Navigate to InviteLogScreen
                  context.push('/invite-log');
                },
              ),
            ),
          ),
          // QR Scanner button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: theme.primaryColor,
                ),
                tooltip: 'Scan QR Code',
                onPressed: () {
                  // Navigate to QR Scanner
                  _openQrScanner(context);
                },
              ),
            ),
          ),
        ],
      ),
      body: referralAsync.when(
        data: (referralCode) {
          debugPrint('✅ Referral code loaded: ${referralCode.code}');

          // Simplified: Get referral service synchronously if possible
          return _buildContentWithService(context, theme, referralCode);
        },
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
        error: (error, stack) {
          debugPrint('❌ Error loading referral code: $error');
          debugPrint('Stack trace: $stack');

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading referral code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Retry by invalidating the provider
                      ref.invalidate(userReferralCodeProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // NEW: Open QR Scanner
  void _openQrScanner(BuildContext context) async {
    try {
      // Option 1: Navigate to QR Scanner screen route
      final result = await context.push('/qr-scanner');

      if (result != null && mounted) {
        debugPrint('🎯 Scanned QR code: $result');

        // Show result
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Scanned: $result'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error opening QR scanner: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Could not open scanner'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Widget _buildContentWithService(
      BuildContext context,
      ThemeData theme,
      ReferralCode referralCode,
      ) {
    // Try to get referral service
    final referralServiceAsync = ref.watch(asyncReferralServiceProvider);

    return referralServiceAsync.when(
      data: (referralService) {
        final referralLink = referralService.getReferralLink(referralCode.code);
        final qrCodeData = referralService.getQRCodeData(referralCode);

        debugPrint('🔵 Referral link: $referralLink');
        debugPrint('🔵 QR Code data: $qrCodeData');
        debugPrint('🔵 QR Code data length: ${qrCodeData.length}');

        return _buildContent(context, theme, referralCode, referralLink, qrCodeData);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        debugPrint('❌ Error loading referral service: $error');

        // Fallback: Build content without service helper methods
        return _buildContentFallback(context, theme, referralCode);
      },
    );
  }

  // Fallback content builder that doesn't rely on service
  Widget _buildContentFallback(
      BuildContext context,
      ThemeData theme,
      ReferralCode referralCode,
      ) {
    // Generate referral link manually
    final referralLink = 'https://triviatycoon.com/invite?code=${referralCode.code}';

    // For QR code, just use the referral code itself or the link
    // This ensures we always have valid QR data
    final qrCodeData = referralLink;

    debugPrint('🟡 Using fallback content generation');
    debugPrint('🟡 Fallback link: $referralLink');
    debugPrint('🟡 Fallback QR data: $qrCodeData');

    return _buildContent(context, theme, referralCode, referralLink, qrCodeData);
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
          // Reward Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF9333EA),
                  Color(0xFF7C3AED),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9333EA).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.card_giftcard_rounded,
                        color: Color(0xFFFFD700),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invite your friends and',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'get rewarded!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Enjoy your rewards with your friends through our rewards points system!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '* Terms & Conditions apply',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Referral Code Section
          _buildInfoCard(
            context: context,
            title: 'YOUR REFERRAL CODE',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    referralCode.code,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                      letterSpacing: 4,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyToClipboard(context, referralCode.code),
                    icon: Icon(
                      Icons.copy_rounded,
                      color: theme.primaryColor,
                    ),
                    tooltip: 'Copy code',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // QR Code Section
          _buildInfoCard(
            context: context,
            title: 'YOUR QR CODE',
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: _buildQRCode(qrCodeData),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Referral Link Section
          _buildInfoCard(
            context: context,
            title: 'YOUR REFERRAL LINK',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      referralLink,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _copyToClipboard(context, referralLink),
                    icon: Icon(
                      Icons.copy_rounded,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                    tooltip: 'Copy link',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Share Button
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _shareInvite(context, referralCode.code, referralLink),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFFF59E0B).withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.share_rounded, size: 22),
              label: const Text(
                'Share',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Rewards Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.blue[700],
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  'How it works',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.person_add_rounded,
                  text: 'Share your code with friends',
                  color: Colors.blue[700]!,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  icon: Icons.verified_rounded,
                  text: 'They sign up using your code',
                  color: Colors.blue[700]!,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  icon: Icons.stars_rounded,
                  text: 'Both of you get bonus rewards!',
                  color: Colors.blue[700]!,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQRCode(String qrCodeData) {
    debugPrint('🎨 Building QR code widget with data: $qrCodeData');

    // Validate QR data
    if (qrCodeData.isEmpty) {
      debugPrint('⚠️ QR code data is empty!');
      return _buildQRCodeError('No QR data available', null);
    }

    // Check data length (QR codes have size limits)
    if (qrCodeData.length > 2953) {
      debugPrint('⚠️ QR code data too long: ${qrCodeData.length} characters');
      return _buildQRCodeError('Data too long for QR code', qrCodeData.length);
    }

    // Try to render QR code
    try {
      debugPrint('✅ Rendering QR code with qr_flutter');

      return QrImageView(
        data: qrCodeData,
        version: QrVersions.auto,
        size: 200.0,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        padding: const EdgeInsets.all(8),
      );
    } catch (e, stack) {
      debugPrint('❌ Error rendering QR code: $e');
      debugPrint('Stack: $stack');

      return _buildQRCodeError('QR Code Error: $e', qrCodeData.length);
    }
  }

  Widget _buildQRCodeError(String message, int? dataLength) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (dataLength != null) ...[
            const SizedBox(height: 8),
            Text(
              'Data: $dataLength chars',
              style: TextStyle(
                fontSize: 11,
                color: Colors.red[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Copied: $text',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareInvite(BuildContext context, String code, String link) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: 'Join Trivia Tycoon and compete with me!\n\n'
              'Use my referral code: $code\n\n'
              'Or sign up directly:\n$link\n\n'
              'We both get bonus rewards when you join!',
          subject: 'Join me on Trivia Tycoon!',
        ),
      );

      if (!context.mounted) return;

      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Shared successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else if (result.status == ShareResultStatus.dismissed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Share cancelled'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Could not share: ${e.toString()}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}