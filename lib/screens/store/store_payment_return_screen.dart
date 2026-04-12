import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/providers/riverpod_providers.dart';

enum StoreReturnMode { purchase, subscription }

class StorePaymentReturnScreen extends ConsumerStatefulWidget {
  final StoreReturnMode mode;
  final Map<String, String> queryParameters;

  const StorePaymentReturnScreen({
    super.key,
    required this.mode,
    required this.queryParameters,
  });

  @override
  ConsumerState<StorePaymentReturnScreen> createState() =>
      _StorePaymentReturnScreenState();
}

class _StorePaymentReturnScreenState
    extends ConsumerState<StorePaymentReturnScreen> {
  bool _loading = true;
  bool _success = false;
  String _title = 'Processing payment...';
  String _message = 'We are syncing your purchase with the backend.';
  String? _details;

  @override
  void initState() {
    super.initState();
    unawaited(_runFlow());
  }

  Future<void> _runFlow() async {
    final status = widget.queryParameters['status']?.toLowerCase() ?? 'success';
    if (status == 'cancel') {
      _setState(
        loading: false,
        success: false,
        title: 'Checkout canceled',
        message: widget.mode == StoreReturnMode.purchase
            ? 'No charge was completed. You can return to the store whenever you are ready.'
            : 'No subscription changes were applied. You can compare plans again anytime.',
      );
      return;
    }

    final playerId = await ref.read(currentUserIdProvider.future);
    switch (widget.mode) {
      case StoreReturnMode.purchase:
        await _handlePurchaseReturn(playerId);
        break;
      case StoreReturnMode.subscription:
        await _handleSubscriptionReturn(playerId);
        break;
    }
  }

  Future<void> _handlePurchaseReturn(String playerId) async {
    final provider =
        widget.queryParameters['provider']?.toLowerCase() ?? 'stripe';
    final sku = widget.queryParameters['sku'];

    if (provider == 'paypal') {
      final orderId = widget.queryParameters['orderId'] ??
          widget.queryParameters['token'] ??
          widget.queryParameters['order_id'];
      if (orderId == null || orderId.isEmpty) {
        _setState(
          loading: false,
          success: false,
          title: 'PayPal return incomplete',
          message:
              'We returned from PayPal without an order id, so capture could not finish.',
        );
        return;
      }

      try {
        _setState(
          loading: true,
          success: false,
          title: 'Capturing PayPal order...',
          message: 'We are finalizing the approved PayPal order on the server.',
        );
        await ref.read(storeServiceProvider).capturePayPalOrder(
              playerId: playerId,
              orderId: orderId,
            );
      } catch (e) {
        _setState(
          loading: false,
          success: false,
          title: 'PayPal capture failed',
          message:
              'The order approval returned, but the backend could not capture it.',
          details: e.toString(),
        );
        return;
      }
    }

    if (sku == null || sku.isEmpty) {
      _setState(
        loading: false,
        success: false,
        title: 'Missing purchase details',
        message:
            'We could not confirm which store item to refresh after checkout.',
      );
      return;
    }

    _setState(
      loading: true,
      success: false,
      title: 'Refreshing inventory...',
      message:
          'The payment provider finished. We are waiting for backend inventory updates.',
    );

    final granted = await _pollInventoryForSku(
      playerId: playerId,
      sku: sku,
      timeout: const Duration(seconds: 30),
    );

    if (granted) {
      _invalidatePurchaseProviders(playerId);
      _setState(
        loading: false,
        success: true,
        title: 'Purchase confirmed',
        message:
            'Your inventory reflects the new purchase. You can head back to the store or keep playing.',
      );
      return;
    }

    _setState(
      loading: false,
      success: false,
      title: 'Still processing',
      message:
          'The payment returned successfully, but the inventory update has not shown up yet. It may still complete after webhook processing finishes.',
    );
  }

  Future<void> _handleSubscriptionReturn(String playerId) async {
    final provider =
        widget.queryParameters['provider']?.toLowerCase() ?? 'stripe';

    _setState(
      loading: true,
      success: false,
      title: provider == 'paypal'
          ? 'Checking PayPal subscription...'
          : 'Checking subscription status...',
      message:
          'We are waiting for the backend subscription record to reflect the latest provider state.',
    );

    final status = await _pollSubscriptionStatus(
      playerId: playerId,
      timeout: const Duration(seconds: 35),
    );

    if (status == null) {
      _setState(
        loading: false,
        success: false,
        title: 'Subscription still processing',
        message:
            'The provider return completed, but the backend subscription state is not active yet. Try refreshing again in a moment.',
      );
      return;
    }

    final isActive = status['isActive'] == true;
    final providerStatus =
        status['providerStatus']?.toString() ?? status['stripeStatus']?.toString();

    _invalidateSubscriptionProviders(playerId);

    if (isActive) {
      _setState(
        loading: false,
        success: true,
        title: 'Subscription active',
        message:
            'Your subscription is active and the backend status is up to date.',
        details: providerStatus == null ? null : 'Status: $providerStatus',
      );
      return;
    }

    _setState(
      loading: false,
      success: false,
      title: 'Subscription not active',
      message:
          'The provider returned, but the latest subscription state is not active.',
      details: providerStatus == null ? null : 'Status: $providerStatus',
    );
  }

  Future<bool> _pollInventoryForSku({
    required String playerId,
    required String sku,
    required Duration timeout,
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      try {
        final inventory =
            await ref.read(storeServiceProvider).getInventory(playerId);
        final items = (inventory['items'] as List<dynamic>? ??
                inventory['inventory'] as List<dynamic>? ??
                const <dynamic>[])
            .whereType<Map>()
            .map((raw) => Map<String, dynamic>.from(raw));

        final found = items.any(
          (item) => item['sku']?.toString().toLowerCase() == sku.toLowerCase(),
        );
        if (found) {
          return true;
        }
      } catch (_) {
        // Ignore transient refresh failures during the poll window.
      }
      await Future.delayed(const Duration(seconds: 3));
    }
    return false;
  }

  Future<Map<String, dynamic>?> _pollSubscriptionStatus({
    required String playerId,
    required Duration timeout,
  }) async {
    final end = DateTime.now().add(timeout);
    Map<String, dynamic>? lastStatus;

    while (DateTime.now().isBefore(end)) {
      try {
        lastStatus =
            await ref.read(storeServiceProvider).getSubscriptionStatus(playerId);
        final isActive = lastStatus['isActive'] == true;
        final providerStatus =
            lastStatus['providerStatus']?.toString().toLowerCase() ??
                lastStatus['stripeStatus']?.toString().toLowerCase() ??
                '';

        if (isActive) return lastStatus;
        if (_isTerminalSubscriptionStatus(providerStatus)) {
          return lastStatus;
        }
      } catch (_) {
        // Ignore transient refresh failures during the poll window.
      }
      await Future.delayed(const Duration(seconds: 3));
    }

    return lastStatus;
  }

  bool _isTerminalSubscriptionStatus(String status) {
    return status == 'canceled' ||
        status == 'cancelled' ||
        status == 'incomplete_expired' ||
        status == 'expired' ||
        status == 'suspended' ||
        status == 'unpaid';
  }

  void _invalidatePurchaseProviders(String playerId) {
    ref.invalidate(storeItemsProvider);
    ref.invalidate(storeSystemStatusProvider);
    ref.invalidate(powerUpInventoryProvider);
    ref.invalidate(storeSubscriptionStatusProvider(playerId));
  }

  void _invalidateSubscriptionProviders(String playerId) {
    ref.invalidate(storeSystemStatusProvider);
    ref.invalidate(storeSubscriptionStatusProvider(playerId));
  }

  void _setState({
    required bool loading,
    required bool success,
    required String title,
    required String message,
    String? details,
  }) {
    if (!mounted) return;
    setState(() {
      _loading = loading;
      _success = success;
      _title = title;
      _message = message;
      _details = details;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = _loading
        ? const Color(0xFF4F46E5)
        : _success
            ? const Color(0xFF059669)
            : const Color(0xFFDC2626);
    final destination =
        widget.mode == StoreReturnMode.purchase ? '/store' : '/offers';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.mode == StoreReturnMode.purchase
              ? 'Store Return'
              : 'Subscription Return',
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: _loading
                        ? SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(accent),
                            ),
                          )
                        : Icon(
                            _success
                                ? Icons.check_circle
                                : Icons.info_outline,
                            color: accent,
                            size: 34,
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF475569),
                  ),
                ),
                if (_details != null && _details!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _details!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (_loading)
                  TextButton(
                    onPressed: _runFlow,
                    child: const Text('Refresh status'),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go(destination),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        widget.mode == StoreReturnMode.purchase
                            ? 'Back to Store'
                            : 'Back to Offers',
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
