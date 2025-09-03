class XPService {
  int _playerXP = 0;

  int get playerXP => _playerXP;

  void addXP(int amount) {
    _playerXP += amount;
    // Optional: add hooks like daily XP cap or streak bonus
  }

  void resetXP() {
    _playerXP = 0;
  }
}
