import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/crypto/crypto_api_error.dart';
import '../../core/models/crypto/crypto_history_item.dart';
import '../../core/models/crypto/crypto_history_response.dart';
import '../../core/models/crypto/crypto_link_wallet_request.dart';
import '../../core/models/crypto/crypto_network.dart';
import '../../core/models/crypto/crypto_transaction_kind.dart';
import '../../core/models/crypto/crypto_transaction_status.dart';
import '../../core/models/crypto/crypto_withdraw_request.dart';
import '../../core/utils/crypto_address_validator.dart';
import '../../game/providers/crypto_providers.dart';
import '../../game/providers/profile_providers.dart';

class CryptoWalletScreen extends ConsumerStatefulWidget {
  const CryptoWalletScreen({super.key});

  @override
  ConsumerState<CryptoWalletScreen> createState() => _CryptoWalletScreenState();
}

class _CryptoWalletScreenState extends ConsumerState<CryptoWalletScreen> {
  Timer? _historyPollingTimer;

  @override
  void dispose() {
    _historyPollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(currentUserCryptoBalanceProvider);
    final stakingAsync = ref.watch(currentUserCryptoStakingProvider);
    final historyAsync = ref.watch(currentUserCryptoHistoryProvider);
    final historyQuery = ref.watch(currentUserCryptoHistoryQueryProvider);

    historyAsync.whenData((history) {
      _syncHistoryPolling(history.hasPendingItems);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        title: const Text('Crypto Wallet'),
        backgroundColor: const Color(0xFF0B1020),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              _refreshWalletData();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          historyAsync.when(
            data: (history) => _WalletLinkStatusCard(
              state: _LinkedWalletState.fromHistory(history.items),
              onLinkWallet: () => _showLinkWalletSheet(context, ref),
            ),
            loading: () => const _LoadingCard(height: 136),
            error: (error, _) => _InfoCard(
              title: 'Wallet status unavailable',
              subtitle: error.toString(),
              icon: Icons.account_balance_wallet_outlined,
              accent: const Color(0xFFF59E0B),
              actionLabel: 'Link wallet',
              onAction: () => _showLinkWalletSheet(context, ref),
            ),
          ),
          const SizedBox(height: 16),
          historyAsync.when(
            data: (history) => _WalletActionsCard(
              state: _LinkedWalletState.fromHistory(history.items),
              onLinkWallet: () => _showLinkWalletSheet(context, ref),
              onWithdraw: () => _showWithdrawSheet(
                context,
                ref,
                _LinkedWalletState.fromHistory(history.items),
              ),
            ),
            loading: () => const _LoadingCard(height: 110),
            error: (_, __) => _WalletActionsCard(
              state: const _LinkedWalletState(isLinked: false),
              onLinkWallet: () => _showLinkWalletSheet(context, ref),
              onWithdraw: null,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: balanceAsync.when(
                  data: (balance) => _MetricCard(
                    title: 'Available',
                    value: '${balance.units}',
                    subtitle: _networkSubtitle(
                      historyAsync.valueOrNull?.items,
                      fallback: balance.unitType,
                    ),
                    icon: Icons.currency_bitcoin_rounded,
                    accent: const Color(0xFF10B981),
                  ),
                  loading: () => const _LoadingCard(height: 138),
                  error: (error, _) => _MetricErrorCard(
                    title: 'Available',
                    message: error.toString(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
              child: stakingAsync.when(
                data: (staking) => _MetricCard(
                  title: 'Staked',
                  value: '${staking.stakedUnits}',
                  subtitle: _networkSubtitle(
                    historyAsync.valueOrNull?.items,
                    fallback: 'Locked units',
                  ),
                  icon: Icons.lock_rounded,
                  accent: const Color(0xFF8B5CF6),
                ),
                  loading: () => const _LoadingCard(height: 138),
                  error: (error, _) => _MetricErrorCard(
                    title: 'Staked',
                    message: error.toString(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          stakingAsync.when(
            data: (staking) => _InfoCard(
              title: 'Staking summary',
              subtitle:
                  'Spendable: ${staking.availableUnits} | Locked: ${staking.stakedUnits}',
              icon: Icons.insights_rounded,
              accent: const Color(0xFF6366F1),
            ),
            loading: () => const _LoadingCard(height: 104),
            error: (error, _) => _InfoCard(
              title: 'Staking summary unavailable',
              subtitle: error.toString(),
              icon: Icons.insights_rounded,
              accent: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 16),
          historyAsync.when(
            data: (history) => _TransactionHistorySection(
              history: history,
              query: historyQuery,
              onRefresh: _refreshWalletData,
              onViewAll: () {
                final nextQuery = historyQuery.pageSize >= 100
                    ? const CryptoHistoryQuery(page: 1, pageSize: 20)
                    : const CryptoHistoryQuery(page: 1, pageSize: 100);
                ref.read(currentUserCryptoHistoryQueryProvider.notifier).state =
                    nextQuery;
              },
              onPreviousPage: historyQuery.page > 1
                  ? () {
                      ref.read(currentUserCryptoHistoryQueryProvider.notifier).state =
                          historyQuery.copyWith(page: historyQuery.page - 1);
                    }
                  : null,
              onNextPage: historyQuery.page < history.totalPages
                  ? () {
                      ref.read(currentUserCryptoHistoryQueryProvider.notifier).state =
                          historyQuery.copyWith(page: historyQuery.page + 1);
                    }
                  : null,
            ),
            loading: () => const _LoadingCard(height: 220),
            error: (error, _) => _InfoCard(
              title: 'Transaction history unavailable',
              subtitle: error.toString(),
              icon: Icons.receipt_long_rounded,
              accent: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshWalletData() {
    ref.invalidate(currentUserCryptoBalanceProvider);
    ref.invalidate(currentUserCryptoStakingProvider);
    ref.invalidate(currentUserCryptoHistoryProvider);
  }

  void _syncHistoryPolling(bool shouldPoll) {
    if (shouldPoll) {
      _historyPollingTimer ??=
          Timer.periodic(const Duration(seconds: 15), (_) => _refreshWalletData());
      return;
    }

    _historyPollingTimer?.cancel();
    _historyPollingTimer = null;
  }

  Future<void> _showLinkWalletSheet(BuildContext context, WidgetRef ref) async {
    final playerId = await ref.read(currentUserIdProvider.future);
    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131A2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _LinkWalletSheet(playerId: playerId),
    );
  }

  Future<void> _showWithdrawSheet(
    BuildContext context,
    WidgetRef ref,
    _LinkedWalletState state,
  ) async {
    final playerId = await ref.read(currentUserIdProvider.future);
    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131A2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _WithdrawSheet(
        playerId: playerId,
        initialNetwork: state.network ?? CryptoNetwork.solana,
        initialAddress: state.displayAddress,
      ),
    );
  }

  String _networkSubtitle(
    List<CryptoHistoryItem>? items, {
    required String fallback,
  }) {
    final network = _LinkedWalletState.fromHistory(items ?? const []).network;
    if (network == null) {
      return fallback;
    }
    return '${network.symbol} units';
  }
}

class _LinkWalletSheet extends ConsumerStatefulWidget {
  const _LinkWalletSheet({
    required this.playerId,
  });

  final String playerId;

  @override
  ConsumerState<_LinkWalletSheet> createState() => _LinkWalletSheetState();
}

class _LinkWalletSheetState extends ConsumerState<_LinkWalletSheet> {
  final TextEditingController _addressController = TextEditingController();
  CryptoNetwork _network = CryptoNetwork.solana;
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Link Wallet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a wallet address so the app can use it for withdrawals later.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<CryptoNetwork>(
            value: _network,
            dropdownColor: const Color(0xFF1B2235),
            decoration: _inputDecoration('Network'),
            items: CryptoNetwork.phaseOneNetworks()
                .map(
                  (network) => DropdownMenuItem<CryptoNetwork>(
                    value: network,
                    child: Text(
                      '${network.displayName} (${network.symbol})',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _network = value;
                _errorText = CryptoAddressValidator.validationMessage(
                  _addressController.text,
                  _network,
                );
              });
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _addressController,
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              setState(() {
                _errorText =
                    CryptoAddressValidator.validationMessage(value, _network);
              });
            },
            decoration: _inputDecoration(
              'Wallet address',
              hintText: 'Paste your wallet address',
              errorText: _errorText,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.link_rounded),
              label: Text(_submitting ? 'Linking...' : 'Link wallet'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hintText,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      errorText: errorText,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF10B981)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }

  Future<void> _submit() async {
    final address = _addressController.text.trim();
    final validation =
        CryptoAddressValidator.validationMessage(address, _network);
    if (validation != null) {
      setState(() {
        _errorText = validation;
      });
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await ref.read(linkWalletProvider)(
            CryptoLinkWalletRequest(
              playerId: widget.playerId,
              walletAddress: address,
              network: _network,
            ),
          );

      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallet linked successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = _friendlyCryptoErrorMessage(error);
      });
    }
  }
}

class _WithdrawSheet extends ConsumerStatefulWidget {
  const _WithdrawSheet({
    required this.playerId,
    required this.initialNetwork,
    this.initialAddress,
  });

  final String playerId;
  final CryptoNetwork initialNetwork;
  final String? initialAddress;

  @override
  ConsumerState<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<_WithdrawSheet> {
  late final TextEditingController _addressController;
  final TextEditingController _unitsController = TextEditingController();
  late CryptoNetwork _network;
  bool _submitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _network = widget.initialNetwork;
    _addressController = TextEditingController(text: widget.initialAddress ?? '');
  }

  @override
  void dispose() {
    _addressController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request Withdrawal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Withdrawals stay pending until the backend settlement worker applies them.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<CryptoNetwork>(
            value: _network,
            dropdownColor: const Color(0xFF1B2235),
            decoration: _inputDecoration('Network'),
            items: CryptoNetwork.phaseOneNetworks()
                .map(
                  (network) => DropdownMenuItem<CryptoNetwork>(
                    value: network,
                    child: Text(
                      '${network.displayName} (${network.symbol})',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _network = value;
                _errorText = CryptoAddressValidator.validationMessage(
                  _addressController.text,
                  _network,
                );
              });
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _unitsController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(
              'Units',
              hintText: 'Enter amount to withdraw',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _addressController,
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              setState(() {
                _errorText =
                    CryptoAddressValidator.validationMessage(value, _network);
              });
            },
            decoration: _inputDecoration(
              'Destination address',
              hintText: 'Withdraw to wallet address',
              errorText: _errorText,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.north_east_rounded),
              label: Text(_submitting ? 'Submitting...' : 'Request withdrawal'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hintText,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      errorText: errorText,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6366F1)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }

  Future<void> _submit() async {
    final address = _addressController.text.trim();
    final validation =
        CryptoAddressValidator.validationMessage(address, _network);
    final units = int.tryParse(_unitsController.text.trim());

    if (units == null || units < 1) {
      setState(() {
        _errorText = 'Enter a withdrawal amount of at least 1 unit.';
      });
      return;
    }

    if (validation != null) {
      setState(() {
        _errorText = validation;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await ref.read(withdrawCryptoProvider)(
            CryptoWithdrawRequest(
              playerId: widget.playerId,
              units: units,
              toWalletAddress: address,
              network: _network,
            ),
          );

      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal requested. Status will remain pending until settled.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = _friendlyCryptoErrorMessage(error);
      });
    }
  }
}

class _LinkedWalletState {
  const _LinkedWalletState({
    required this.isLinked,
    this.displayAddress,
    this.network,
  });

  final bool isLinked;
  final String? displayAddress;
  final CryptoNetwork? network;

  factory _LinkedWalletState.fromHistory(List<CryptoHistoryItem> items) {
    for (final item in items) {
      if (item.kind == CryptoTransactionKind.walletLink) {
        final inferredNetwork = _inferNetworkFromAddress(item.receiptRef);
        return _LinkedWalletState(
          isLinked: true,
          displayAddress: item.receiptRef,
          network: inferredNetwork,
        );
      }
    }

    return const _LinkedWalletState(isLinked: false);
  }

  static CryptoNetwork? _inferNetworkFromAddress(String? address) {
    if (address == null || address.trim().isEmpty) {
      return null;
    }

    for (final network in CryptoNetwork.values) {
      if (CryptoAddressValidator.isValid(address, network)) {
        return network;
      }
    }
    return null;
  }
}

class _WalletLinkStatusCard extends StatelessWidget {
  const _WalletLinkStatusCard({
    required this.state,
    required this.onLinkWallet,
  });

  final _LinkedWalletState state;
  final VoidCallback onLinkWallet;

  @override
  Widget build(BuildContext context) {
    if (state.isLinked) {
      return _InfoCard(
        title: 'Wallet linked',
        subtitle: state.displayAddress == null || state.displayAddress!.isEmpty
            ? 'A ${state.network?.symbol ?? 'crypto'} wallet is already on file for this player.'
            : 'Connected ${state.network?.symbol ?? 'wallet'}: ${state.displayAddress}',
        icon: Icons.verified_rounded,
        accent: const Color(0xFF10B981),
        actionLabel: 'Update wallet',
        onAction: onLinkWallet,
      );
    }

    return _InfoCard(
      title: 'Wallet not linked',
      subtitle:
          'Link a wallet address to prepare for withdrawals and future crypto actions.',
      icon: Icons.account_balance_wallet_outlined,
      accent: const Color(0xFF6366F1),
      actionLabel: 'Link wallet',
      onAction: onLinkWallet,
    );
  }
}

class _WalletActionsCard extends StatelessWidget {
  const _WalletActionsCard({
    required this.state,
    required this.onLinkWallet,
    required this.onWithdraw,
  });

  final _LinkedWalletState state;
  final VoidCallback onLinkWallet;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(const Color(0xFF334155)),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onLinkWallet,
              icon: const Icon(Icons.link_rounded),
              label: Text(state.isLinked ? 'Update wallet' : 'Link wallet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: onWithdraw,
              icon: const Icon(Icons.north_east_rounded),
              label: const Text('Withdraw'),
              style: FilledButton.styleFrom(
                backgroundColor: state.isLinked
                    ? const Color(0xFF6366F1)
                    : Colors.white.withValues(alpha: 0.12),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricErrorCard extends StatelessWidget {
  const _MetricErrorCard({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: title,
      subtitle: message,
      icon: Icons.error_outline_rounded,
      accent: const Color(0xFFEF4444),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(actionLabel!),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({
    required this.height,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: _cardDecoration(const Color(0xFF334155)),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _TransactionHistorySection extends StatelessWidget {
  const _TransactionHistorySection({
    required this.history,
    required this.query,
    required this.onRefresh,
    required this.onViewAll,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final CryptoHistoryResponse history;
  final CryptoHistoryQuery query;
  final VoidCallback onRefresh;
  final VoidCallback onViewAll;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  @override
  Widget build(BuildContext context) {
    if (history.items.isEmpty) {
      return const _InfoCard(
        title: 'No crypto activity yet',
        subtitle: 'Your wallet history will appear here after linking, staking, or withdrawing.',
        icon: Icons.receipt_long_rounded,
        accent: Color(0xFF334155),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(const Color(0xFF334155)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Transaction History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text(query.pageSize >= 100 ? 'Show recent' : 'View all'),
              ),
              IconButton(
                onPressed: onRefresh,
                tooltip: 'Refresh history',
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (history.hasPendingItems)
            Text(
              'Pending withdrawals detected. History refreshes every 15 seconds while this screen is open.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 14),
          ...history.items.take(query.pageSize >= 100 ? history.items.length : 6).map(
                _TransactionHistoryTile.new,
              ),
          if (history.totalPages > 1) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onPreviousPage,
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                ),
                const Spacer(),
                Text(
                  'Page ${history.page} of ${history.totalPages}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onNextPage,
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Next'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionHistoryTile extends StatelessWidget {
  const _TransactionHistoryTile(this.item);

  final CryptoHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final isPositive = item.unitsDelta > 0;
    final statusColor = switch (item.status) {
      CryptoTransactionStatus.pending => const Color(0xFFF59E0B),
      CryptoTransactionStatus.applied => const Color(0xFF10B981),
      CryptoTransactionStatus.failed => const Color(0xFFEF4444),
      CryptoTransactionStatus.reversed => const Color(0xFFF97316),
      CryptoTransactionStatus.unknown => Colors.white54,
    };

    final statusIcon = switch (item.status) {
      CryptoTransactionStatus.pending => Icons.schedule_rounded,
      CryptoTransactionStatus.applied => Icons.check_circle_rounded,
      CryptoTransactionStatus.failed => Icons.cancel_rounded,
      CryptoTransactionStatus.reversed => Icons.undo_rounded,
      CryptoTransactionStatus.unknown => Icons.help_outline_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.kind.displayLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.status.displayLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.receiptRef != null && item.receiptRef!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.receiptRef!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isPositive ? '+' : ''}${item.unitsDelta}',
            style: TextStyle(
              color: isPositive
                  ? const Color(0xFF10B981)
                  : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration(Color accent) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF151B2D),
        accent.withValues(alpha: 0.10),
      ],
    ),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.08),
    ),
    boxShadow: [
      BoxShadow(
        color: accent.withValues(alpha: 0.08),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

String _friendlyCryptoErrorMessage(Object error) {
  if (error is CryptoApiException) {
    switch (error.code) {
      case 'WALLET_NOT_LINKED':
        return 'Link a wallet first before requesting a withdrawal.';
      case 'MIN_WITHDRAWAL':
        final minimum = error.details['minimumUnits'] ?? error.details['minUnits'];
        if (minimum != null) {
          return 'Minimum withdrawal is $minimum units.';
        }
        return 'This withdrawal is below the minimum allowed amount.';
      case 'INSUFFICIENT_CRYPTO_BALANCE':
        final available = error.details['availableUnits'];
        final requested = error.details['requestedUnits'];
        if (available != null && requested != null) {
          return 'Not enough balance. Available: $available units, requested: $requested units.';
        }
        return 'You do not have enough crypto balance for this withdrawal.';
      default:
        return error.message;
    }
  }

  return error.toString();
}
