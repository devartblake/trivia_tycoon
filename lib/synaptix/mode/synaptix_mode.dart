/// Audience mode for the Synaptix platform.
///
/// Determines UI tone, card emphasis, label vocabulary, and motion behavior
/// across the app. Mapped from the user's saved age group on bootstrap.
enum SynaptixMode {
  /// Bright surfaces, soft corners, simpler labels, larger touch targets.
  kids,

  /// Strongest Synaptix identity: neon accents, competition-forward, social-energy.
  teen,

  /// Cleaner layout, restrained animation, mastery/ranking emphasis.
  adult,
}
