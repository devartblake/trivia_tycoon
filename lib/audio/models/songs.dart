 class Song {
  final String filename;
  final String name;
  final String? artist;
  final String? genre;
  final String? duration; // Format: MM:SS
  final String? albumArtUrl;  // URL for album art
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

 // List of available songs
 const Set<Song> songs = {
   Song(
     'Mr_Smith-Azurl.mp3',
     'Azul',
     artist: 'Mr smith',
     genre: 'Chill',
     duration: '03:45',
     albumArtUrl: 'https://example.com/azul.jpg',
   ),
   Song(
     'Mr_Smith-Sonorus.mp3',
     'Azul',
     artist: 'Mr smith',
     genre: 'Ambient',
     duration: '04:12',
     albumArtUrl: 'https://example.com/sonorus.jpg',
   ),
   Song(
     'Mr_Smith-Sunday_Solitude.mp3',
     'Azul',
     artist: 'Mr smith',
     genre: 'Relaxing',
     duration: '05:20',
     albumArtUrl: 'https://example.com/sunday_solitude.jpg',
     isExclusive: true, // This song requires a purchase
   ),
   Song(
     'Mr_Smith-Starlit_Dreams.mp3',
     'Starlit Dreams',
     artist: 'Mr smith',
     genre: 'Lo-Fi',
     duration: '04:00',
     albumArtUrl: 'https://example.com/starlit_dreams.jpg',
     isExclusive: true, // This song requires a purchase
   ),
 };
