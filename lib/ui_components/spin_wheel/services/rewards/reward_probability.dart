import 'dart:math';

class RewardProbability {
  final Random _random = Random();

  double baseJackpotChance = 0.02;
  double baseSmallPrizeChance = 0.6;
  double baseMediumPrizeChance = 0.3;
  double baseLargePrizeChance = 0.08;

  int userLevel = 1;
  int winStreak = 0;
  bool recentlyWonJackpot = false;
  int exclusiveCurrency = 0;
  late DateTime lastJackpotWin;

  double _getJackpotModifier() {
    if (recentlyWonJackpot) {
      Duration timeSinceWin = DateTime.now().difference(lastJackpotWin);
      double reductionFactor = (12 - timeSinceWin.inHours) / 12;
      return max(0.01, baseJackpotChance * reductionFactor);
    }
    return baseJackpotChance + (winStreak * 0.005);
  }

  double _getExclusiveCurrencyModifier() {
    return exclusiveCurrency > 0 ? min(0.01 * exclusiveCurrency, 0.05) : 0.0;
  }

  Map<String, double> getAdjustedProbabilities() {
    double jackpotChance = _getJackpotModifier() + _getExclusiveCurrencyModifier();
    double smallPrizeChance = baseSmallPrizeChance - (userLevel * 0.002);
    double mediumPrizeChance = baseMediumPrizeChance + (userLevel * 0.001);
    double largePrizeChance = baseLargePrizeChance;

    double total = jackpotChance + smallPrizeChance + mediumPrizeChance + largePrizeChance;
    return {
      "jackpot": jackpotChance / total,
      "small": smallPrizeChance / total,
      "medium": mediumPrizeChance / total,
      "large": largePrizeChance / total,
    };
  }

  String spinWheel() {
    Map<String, double> probabilities = getAdjustedProbabilities();
    double roll = _random.nextDouble();
    double cumulative = 0.0;

    for (var entry in probabilities.entries) {
      cumulative += entry.value;
      if (roll < cumulative) {
        if (entry.key == "jackpot") {
          recentlyWonJackpot = true;
          lastJackpotWin = DateTime.now();
        }
        return entry.key;
      }
    }
    return "small";
  }
}
