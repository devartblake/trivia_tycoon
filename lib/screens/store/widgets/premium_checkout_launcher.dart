import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/store/store_return_url_builder.dart';
import '../../../game/providers/riverpod_providers.dart';

class PremiumCheckoutLauncher {
  static Future<void> launchSubscriptionCheckout({
    required BuildContext context,
    required WidgetRef ref,
    required String tier,
    required String billingPeriod,
    required String purchaseLabel,
  }) async {
    final status = await ref.read(storeSystemStatusProvider.future);
    if (status['storeEnabled'] == false || status['paymentsEnabled'] == false) {
      _showSnack(
        context,
        status['message']?.toString() ??
            'Subscriptions are currently unavailable.',
        const Color(0xFFEF4444),
      );
      return;
    }

    final useStripe = await _chooseProvider(
      context,
      stripeEnabled: status['stripeEnabled'] == true,
      payPalEnabled: status['payPalEnabled'] == true,
    );
    if (useStripe == null || !context.mounted) return;

    final playerId = await ref.read(currentUserIdProvider.future);
    final storeService = ref.read(storeServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = useStripe
          ? await storeService.createStripeSubscriptionCheckout(
              playerId: playerId,
              tier: tier,
              billingPeriod: billingPeriod,
              successUrl: StoreReturnUrlBuilder.subscriptionSuccess(
                provider: 'stripe',
                tier: tier,
                billingPeriod: billingPeriod,
              ),
              cancelUrl: StoreReturnUrlBuilder.subscriptionCancel(
                provider: 'stripe',
                tier: tier,
                billingPeriod: billingPeriod,
              ),
            )
          : await storeService.createPayPalSubscription(
              playerId: playerId,
              tier: tier,
              billingPeriod: billingPeriod,
              returnUrl: StoreReturnUrlBuilder.subscriptionSuccess(
                provider: 'paypal',
                tier: tier,
                billingPeriod: billingPeriod,
              ),
              cancelUrl: StoreReturnUrlBuilder.subscriptionCancel(
                provider: 'paypal',
                tier: tier,
                billingPeriod: billingPeriod,
              ),
            );

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      final redirectUrl =
          (useStripe ? response['checkoutUrl'] : response['approveUrl'])
              ?.toString();
      if (redirectUrl == null || redirectUrl.isEmpty) {
        _showSnack(
          context,
          'The subscription provider did not return a redirect URL.',
          const Color(0xFFEF4444),
        );
        return;
      }

      final uri = Uri.tryParse(redirectUrl);
      if (uri == null || !await canLaunchUrl(uri)) {
        _showSnack(
          context,
          'Unable to open the subscription page on this device.',
          const Color(0xFFEF4444),
        );
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
      ref.invalidate(storeSystemStatusProvider);
      ref.invalidate(storeSubscriptionStatusProvider(playerId));
      ref.invalidate(premiumAccessStatusProvider);

      _showSnack(
        context,
        useStripe
            ? '$purchaseLabel checkout opened. Premium status will refresh when you return.'
            : '$purchaseLabel approval opened. Premium status will refresh after provider confirmation.',
        const Color(0xFF10B981),
      );
    } on ApiRequestException catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      _showSnack(context, e.message, const Color(0xFFEF4444));
    } catch (_) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      _showSnack(
        context,
        'Subscription checkout failed. Please try again.',
        const Color(0xFFEF4444),
      );
    }
  }

  static Future<bool?> _chooseProvider(
    BuildContext context, {
    required bool stripeEnabled,
    required bool payPalEnabled,
  }) async {
    if (stripeEnabled && !payPalEnabled) return true;
    if (!stripeEnabled && payPalEnabled) return false;
    if (!stripeEnabled && !payPalEnabled) {
      _showSnack(
        context,
        'No payment providers are currently available.',
        const Color(0xFFEF4444),
      );
      return null;
    }

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose subscription provider',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              _providerTile(
                context,
                label: 'Stripe',
                subtitle: 'Hosted checkout and billing portal support',
                icon: Icons.credit_card,
                color: const Color(0xFF4F46E5),
                value: true,
              ),
              const SizedBox(height: 12),
              _providerTile(
                context,
                label: 'PayPal',
                subtitle: 'Approval flow with webhook-driven status updates',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF0EA5E9),
                value: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _providerTile(
    BuildContext context, {
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(value),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  static void _showSnack(BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
