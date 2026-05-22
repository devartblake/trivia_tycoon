enum RewardMechanism {
  reactor,
  arcadeSpin,
  daily,
  mission,
  event;

  static RewardMechanism fromString(String? value) {
    switch (value) {
      case 'reactor':
        return RewardMechanism.reactor;
      case 'arcade_spin':
        return RewardMechanism.arcadeSpin;
      case 'daily':
        return RewardMechanism.daily;
      case 'mission':
        return RewardMechanism.mission;
      case 'event':
        return RewardMechanism.event;
      default:
        return RewardMechanism.reactor;
    }
  }

  String toJsonString() {
    switch (this) {
      case RewardMechanism.reactor:
        return 'reactor';
      case RewardMechanism.arcadeSpin:
        return 'arcade_spin';
      case RewardMechanism.daily:
        return 'daily';
      case RewardMechanism.mission:
        return 'mission';
      case RewardMechanism.event:
        return 'event';
    }
  }
}
