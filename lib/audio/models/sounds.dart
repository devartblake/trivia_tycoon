/// Maps an SfxType to a list of potential audio filenames.
/// These filenames should correspond to files placed under your assets/sfx/ directory.
List<String> soundTypeToFilename(SfxType type) => switch (type) {
  SfxType.huhsh => const [
    'hash1.mp3',
    'hash2.mp3',
    'hash3.mp3',
  ],
  SfxType.wssh => const [
    'wssh1.mp3',
    'wssh2.mp3',
    'dsht1.mp3',
    'ws1.mp3',
    'spsh1.mp3',
    'hh1.mp3',
    'hh2.mp3',
    'kss1.mp3',
  ],
  SfxType.buttonTap => const [
    'k1.mp3',
    'k2.mp3',
    'p1.mp3',
    'p2.mp3',
  ],
  SfxType.congrats => const [
    'yay1.mp3',
    'wehee1.mp3',
    'oo1.mp3',
  ],
  SfxType.erase => const [
    'fwfwfwfwfw1.mp3',
    'fwfwfwfw1.mp3',
  ],
  SfxType.swishSwish => const [
    'swishswish1.mp3',
  ]
};

/// Returns the playback volume for a given [SfxType].
/// Adjust these values as needed for your application's audio balance.
double soundTypeToVolume(SfxType type) {
  switch (type) {
    case SfxType.huhsh:
      return 0.4;
    case SfxType.wssh:
      return 0.2;
    case SfxType.buttonTap:
    case SfxType.congrats:
    case SfxType.erase:
    case SfxType.swishSwish:
      return 1.0;
  }
}

/// Enum representing the different types of sound effects used in the app.
enum SfxType {
  huhsh,
  wssh,
  buttonTap,
  congrats,
  erase,
  swishSwish,
}
