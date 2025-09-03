import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/settings/purchase_settings_service.dart';
import '../../audio/models/songs.dart';
import '../../game/providers/riverpod_providers.dart';

enum MusicFilter { all, purchased, exclusive }

final purchaseSettingsServiceProvider = Provider<PurchaseSettingsService>((ref) {
  return ref.read(serviceManagerProvider).purchaseSettingsService;
});

class MusicScreen extends ConsumerStatefulWidget {
  const MusicScreen({super.key});

  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen> {
  late final PurchaseSettingsService purchaseService;

  MusicFilter _selectedFilter = MusicFilter.all;
  List<String> _purchasedSongs = [];

  @override
  void initState() {
    super.initState();
    purchaseService = ref.read(purchaseSettingsServiceProvider);
    _loadPurchasedSongs();
  }

  Future<void> _loadPurchasedSongs() async {
    final purchased = await purchaseService.getPurchasedSongs();
    setState(() {
      _purchasedSongs = purchased;
    });
  }

  Future<void> _purchaseSong(Song song) async {
    await purchaseService.addPurchasedItem(song.filename);
    await _loadPurchasedSongs();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${song.name} purchased successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exclusiveSongs = songs.where((song) => song.isExclusive).toSet();
    final purchasedSet = songs.where((song) => _purchasedSongs.contains(song.filename)).toSet();

    Set<Song> displayedSongs;
    switch (_selectedFilter) {
      case MusicFilter.purchased:
        displayedSongs = purchasedSet;
        break;
      case MusicFilter.exclusive:
        displayedSongs = exclusiveSongs;
        break;
      default:
        displayedSongs = songs;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Music Library')),
      body: Column(
        children: [
          // Filter toggle buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: ToggleButtons(
              isSelected: [
                _selectedFilter == MusicFilter.all,
                _selectedFilter == MusicFilter.purchased,
                _selectedFilter == MusicFilter.exclusive,
              ],
              onPressed: (index) {
                setState(() {
                  _selectedFilter = MusicFilter.values[index];
                });
              },
              borderRadius: BorderRadius.circular(10),
              children: const [
                Padding(padding: EdgeInsets.all(8.0), child: Text('All Songs')),
                Padding(padding: EdgeInsets.all(8.0), child: Text('Purchased')),
                Padding(padding: EdgeInsets.all(8.0), child: Text('Exclusive')),
              ],
            ),
          ),

          // Songs list
          Expanded(
            child: ListView.builder(
              itemCount: displayedSongs.length,
              itemBuilder: (context, index) {
                final song = displayedSongs.elementAt(index);
                final isPurchased = _purchasedSongs.contains(song.filename);

                return ListTile(
                  leading: Icon(
                    isPurchased ? Icons.music_note : Icons.lock,
                    color: isPurchased ? Colors.green : Colors.grey,
                  ),
                  title: Text(song.name),
                  subtitle: Text(song.artist ?? 'Unknown Artist'),
                  trailing: isPurchased
                      ? const Icon(Icons.play_arrow)
                      : ElevatedButton(
                    onPressed: () => _purchaseSong(song),
                    child: const Text('Buy'),
                  ),
                  onTap: isPurchased
                      ? () {
                    // TODO: Implement playback
                  }
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
