class Song {
  final String filename;
  final String name;
  final String? artist;
  final String? genre;
  final String? duration; // Format: MM:SS
  final String? albumArtUrl;
  final bool isExclusive; // If true, song requires purchase

  const Song(
    this.filename,
    this.name, {
    this.artist,
    this.genre,
    this.duration,
    this.albumArtUrl,
    this.isExclusive = false,
  });

  @override
  String toString() => 'Song<$filename>';
}

const Set<Song> songs = {
  Song('around_the_world.mp3', 'Around the World', genre: 'Lo-Fi'),
  Song('autumn_days_lofi.mp3', 'Autumn Days', genre: 'Lo-Fi'),
  Song('believing_in_goods_things.mp3', 'Believing in Good Things',
      genre: 'Chill'),
  Song('breezing.mp3', 'Breezing', genre: 'Ambient'),
  Song('end_game.mp3', 'End Game', genre: 'Game'),
  Song('holding_hands.mp3', 'Holding Hands', genre: 'Chill'),
  Song('moving_on.mp3', 'Moving On', genre: 'Lo-Fi'),
  Song('new_starts_beat.mp3', 'New Starts Beat', genre: 'Upbeat'),
  Song('patience.mp3', 'Patience', genre: 'Ambient'),
  Song('pillow_days.mp3', 'Pillow Days', genre: 'Lo-Fi'),
  Song('sweetheart_waltz.mp3', 'Sweetheart Waltz', genre: 'Chill'),
  Song('what_it_feels_like.mp3', 'What It Feels Like', genre: 'Ambient'),
};
