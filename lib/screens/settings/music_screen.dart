import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class _MusicScreenState extends ConsumerState<MusicScreen>
    with TickerProviderStateMixin {
  late final PurchaseSettingsService purchaseService;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  late List<AnimationController> _itemControllers;

  MusicFilter _selectedFilter = MusicFilter.all;
  List<String> _purchasedSongs = [];

  @override
  void initState() {
    super.initState();
    purchaseService = ref.read(purchaseSettingsServiceProvider);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));

    _itemControllers = List.generate(
      songs.length,
          (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 50)),
        vsync: this,
      ),
    );

    _loadPurchasedSongs();
    _startAnimations();
  }

  void _startAnimations() {
    _animationController!.forward();
    for (int i = 0; i < _itemControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 300 + (i * 50)), () {
        if (mounted) _itemControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
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
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${song.name} purchased successfully!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
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
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: _buildAppBar(),
      body: _fadeAnimation != null
          ? FadeTransition(
        opacity: _fadeAnimation!,
        child: _buildBody(displayedSongs),
      )
          : _buildBody(displayedSongs),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      title: const Text(
        'Music Library',
        style: TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }

  Widget _buildBody(Set<Song> displayedSongs) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        _buildStatsSection(),
        _buildFilterSection(),
        _buildSongsSection(displayedSongs),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildStatsSection() {
    final totalSongs = songs.length;
    final purchasedCount = _purchasedSongs.length;
    final exclusiveCount = songs.where((song) => song.isExclusive).length;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.library_music_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Music Collection',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage your audio library',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Total Songs', totalSongs.toString(), Icons.music_note_rounded),
                ),
                Expanded(
                  child: _buildStatItem('Purchased', purchasedCount.toString(), Icons.shopping_cart_rounded),
                ),
                Expanded(
                  child: _buildStatItem('Exclusive', exclusiveCount.toString(), Icons.star_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF64748B).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: MusicFilter.values.map((filter) {
                final isSelected = _selectedFilter == filter;
                final color = _getFilterColor(filter);

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: isSelected ? LinearGradient(colors: [color, color.withOpacity(0.8)]) : null,
                        color: isSelected ? null : color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withOpacity(isSelected ? 0.3 : 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getFilterName(filter),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsSection(Set<Song> displayedSongs) {
    if (displayedSongs.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF64748B).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.music_off_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No songs found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try changing your filter selection',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final song = displayedSongs.elementAt(index);
          final isPurchased = _purchasedSongs.contains(song.filename);

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _itemControllers[index % _itemControllers.length],
              curve: Curves.easeOutBack,
            )),
            child: _buildSongItem(song, isPurchased, index),
          );
        },
        childCount: displayedSongs.length,
      ),
    );
  }

  Widget _buildSongItem(Song song, bool isPurchased, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isPurchased
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFF64748B).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPurchased
                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                  : [const Color(0xFF64748B), const Color(0xFF475569)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isPurchased ? Icons.music_note_rounded : Icons.lock_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          song.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              song.artist ?? 'Unknown Artist',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF64748B).withOpacity(0.8),
              ),
            ),
            if (song.isExclusive) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 12,
                    color: Colors.amber.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Exclusive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: isPurchased
            ? Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Color(0xFF10B981),
            size: 20,
          ),
        )
            : ElevatedButton.icon(
          onPressed: () => _purchaseSong(song),
          icon: const Icon(Icons.shopping_cart_rounded, size: 16),
          label: const Text('Buy'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        onTap: isPurchased
            ? () {
          // TODO: Implement playback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playing ${song.name}...'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
            : null,
      ),
    );
  }

  Color _getFilterColor(MusicFilter filter) {
    switch (filter) {
      case MusicFilter.all:
        return const Color(0xFF6366F1);
      case MusicFilter.purchased:
        return const Color(0xFF10B981);
      case MusicFilter.exclusive:
        return const Color(0xFFF59E0B);
    }
  }

  String _getFilterName(MusicFilter filter) {
    switch (filter) {
      case MusicFilter.all:
        return 'All Songs';
      case MusicFilter.purchased:
        return 'Purchased';
      case MusicFilter.exclusive:
        return 'Exclusive';
    }
  }
}
