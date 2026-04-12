enum CryptoTransactionKind {
  walletLink(
    apiValue: 'crypto-wallet-link',
    displayLabel: 'Wallet linked',
    direction: CryptoTransactionDirection.neutral,
  ),
  withdrawRequest(
    apiValue: 'crypto-withdraw-request',
    displayLabel: 'Withdrawal request',
    direction: CryptoTransactionDirection.negative,
  ),
  stakeLock(
    apiValue: 'crypto-stake-lock',
    displayLabel: 'Staked',
    direction: CryptoTransactionDirection.negative,
  ),
  stakeUnlock(
    apiValue: 'crypto-stake-unlock',
    displayLabel: 'Unstaked',
    direction: CryptoTransactionDirection.positive,
  ),
  prizePoolFund(
    apiValue: 'crypto-prize-pool-fund',
    displayLabel: 'Contributed to prize pool',
    direction: CryptoTransactionDirection.negative,
  ),
  prizePoolPayout(
    apiValue: 'crypto-prize-pool-payout',
    displayLabel: 'Prize pool winnings',
    direction: CryptoTransactionDirection.positive,
  ),
  unknown(
    apiValue: 'unknown',
    displayLabel: 'Crypto activity',
    direction: CryptoTransactionDirection.neutral,
  );

  const CryptoTransactionKind({
    required this.apiValue,
    required this.displayLabel,
    required this.direction,
  });

  final String apiValue;
  final String displayLabel;
  final CryptoTransactionDirection direction;

  static CryptoTransactionKind fromApiValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return CryptoTransactionKind.unknown;
    }

    final normalized = value.trim().toLowerCase();
    for (final kind in CryptoTransactionKind.values) {
      if (kind.apiValue == normalized) {
        return kind;
      }
    }
    return CryptoTransactionKind.unknown;
  }
}

enum CryptoTransactionDirection {
  positive,
  negative,
  neutral,
}
