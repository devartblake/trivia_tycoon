class WalletService {
  int _coins = 0;
  int _gems = 0;

  int get coins => _coins;
  int get gems => _gems;

  void addCoins(int amount) {
    if (amount <= 0) return;
    _coins += amount;
  }

  void addGems(int amount) {
    if (amount <= 0) return;
    _gems += amount;
  }

  /// Optional: spend helpers (future use)
  bool spendCoins(int amount) {
    if (amount <= 0) return true;
    if (_coins < amount) return false;
    _coins -= amount;
    return true;
  }

  bool spendGems(int amount) {
    if (amount <= 0) return true;
    if (_gems < amount) return false;
    _gems -= amount;
    return true;
  }
}
