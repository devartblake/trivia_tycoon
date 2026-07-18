import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dto/champion_round_events.dart';
import '../../game/models/champion_spectator.dart';
import '../../game/providers/arcade_providers.dart'
    show championSpectatorProvider;
import '../../game/providers/core_providers.dart' show apiServiceProvider;
import '../../game/providers/hub_providers.dart';
import '../../game/providers/learning_providers.dart'
    show currentPlayerIdProvider;

/// Live Champion vs Tier match screen. Joins the event's realtime group, shows
/// the current round (or an active duel the viewer is in) with a countdown,
/// submits answers, and — for the champion — offers a "call out a challenger"
/// roster picker to start head-to-head duels.
class ChampionLiveScreen extends ConsumerStatefulWidget {
  final String gameEventId;
  const ChampionLiveScreen({super.key, required this.gameEventId});

  @override
  ConsumerState<ChampionLiveScreen> createState() => _ChampionLiveScreenState();
}

class _ChampionLiveScreenState extends ConsumerState<ChampionLiveScreen> {
  ChampionRoundStartedDto? _round;
  ChampionRoundResolvedDto? _lastResolved;
  ChampionMatchEndedDto? _ended;
  ChampionDuelStartedDto? _duel;
  ChampionDuelResolvedDto? _duelResolved;

  String? _playerId;
  String? _championId;
  int _duelsRemaining = 0;

  String? _selectedOptionId; // round answer
  String? _duelSelectedOptionId; // duel answer
  bool _submitting = false;
  bool _duelSubmitting = false;
  bool _startingDuel = false;

  Timer? _ticker;
  Timer? _duelClear;

  @override
  void initState() {
    super.initState();
    // A single always-on tick keeps every countdown fresh.
    _ticker = Timer.periodic(const Duration(milliseconds: 250),
        (_) => mounted ? setState(() {}) : null);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _playerId = await ref.read(currentPlayerIdProvider.future);
      if (!mounted) return;
      try {
        await ref
            .read(notificationHubProvider)
            .joinGameEvent(widget.gameEventId);
      } catch (_) {
        // Not connected yet — stream listeners still catch events once it is.
      }
      await _replayFromSnapshot();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _duelClear?.cancel();
    super.dispose();
  }

  bool get _amIChampion => _playerId != null && _playerId == _championId;
  bool _amInDuel(ChampionDuelStartedDto d) =>
      _playerId == d.championPlayerId || _playerId == d.challengerPlayerId;

  Future<void> _replayFromSnapshot() async {
    final snap =
        await ref.read(apiServiceProvider).getLiveSnapshot(widget.gameEventId);
    if (!mounted || snap == null) return;
    setState(() {
      _championId = snap.championPlayerId;
      _duelsRemaining = snap.duelsRemaining;
    });
    if (_ended != null) return;
    if (snap.currentDuel != null) _onDuelStarted(snap.currentDuel!);
    if (_round == null && snap.currentRound != null) {
      _onRoundStarted(snap.currentRound!);
    }
  }

  bool _isForThisEvent(String eventId) => eventId == widget.gameEventId;

  void _onRoundStarted(ChampionRoundStartedDto r) {
    if (!_isForThisEvent(r.gameEventId)) return;
    setState(() {
      _round = r;
      _lastResolved = null;
      _selectedOptionId = null;
    });
  }

  void _onRoundResolved(ChampionRoundResolvedDto r) {
    if (!_isForThisEvent(r.gameEventId)) return;
    setState(() => _lastResolved = r);
    _refreshSpectator();
  }

  /// Re-pull the spectator view so the elimination cam reflects the fresh
  /// casualties. Cheap: free viewers get counts only, premium the full feed.
  void _refreshSpectator() {
    ref.invalidate(championSpectatorProvider(widget.gameEventId));
  }

  void _onMatchEnded(ChampionMatchEndedDto r) {
    if (!_isForThisEvent(r.gameEventId)) return;
    setState(() => _ended = r);
  }

  void _onDuelStarted(ChampionDuelStartedDto d) {
    if (!_isForThisEvent(d.gameEventId)) return;
    _duelClear?.cancel();
    setState(() {
      _duel = d;
      _duelResolved = null;
      _duelSelectedOptionId = null;
    });
  }

  void _onDuelResolved(ChampionDuelResolvedDto d) {
    if (!_isForThisEvent(d.gameEventId)) return;
    setState(() {
      _duelResolved = d;
      if (_amIChampion && _duelsRemaining > 0) _duelsRemaining--;
    });
    // Show the result briefly, then return to the round view.
    _duelClear?.cancel();
    _duelClear = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _duel = null);
    });
    _refreshSpectator();
  }

  Future<void> _submitRound(String optionId) async {
    if (_submitting || _selectedOptionId != null) return;
    setState(() {
      _selectedOptionId = optionId;
      _submitting = true;
    });
    try {
      await ref.read(apiServiceProvider).submitRoundAnswer(
          gameEventId: widget.gameEventId, optionId: optionId);
    } catch (_) {
      // Selection stays; the round resolves regardless.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitDuel(String optionId) async {
    if (_duelSubmitting || _duelSelectedOptionId != null) return;
    setState(() {
      _duelSelectedOptionId = optionId;
      _duelSubmitting = true;
    });
    try {
      await ref.read(apiServiceProvider).submitDuelAnswer(
          gameEventId: widget.gameEventId, optionId: optionId);
    } catch (_) {
      // Selection stays; the duel resolves regardless.
    } finally {
      if (mounted) setState(() => _duelSubmitting = false);
    }
  }

  Future<void> _openDuelPicker() async {
    if (_startingDuel) return;
    final participants = await ref
        .read(apiServiceProvider)
        .getEventParticipants(widget.gameEventId);
    if (!mounted) return;
    final challengers =
        participants.where((p) => !p.eliminated && !p.isChampion).toList();
    if (challengers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No challengers left to call out.')),
      );
      return;
    }

    final picked = await showModalBottomSheet<ChampionParticipant>(
      context: context,
      backgroundColor: const Color(0xFF231145),
      showDragHandle: true,
      builder: (ctx) => _DuelPicker(challengers: challengers),
    );
    if (picked == null || !mounted) return;
    await _startDuel(picked);
  }

  Future<void> _startDuel(ChampionParticipant target) async {
    setState(() => _startingDuel = true);
    try {
      final status = await ref.read(apiServiceProvider).startChampionDuel(
          gameEventId: widget.gameEventId, challengerPlayerId: target.playerId);
      if (!mounted) return;
      final ok = status == 'Started';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'You called out ${target.displayName}!'
            : 'Could not start duel: $status'),
        backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      ));
    } finally {
      if (mounted) setState(() => _startingDuel = false);
    }
  }

  int _secondsLeft(DateTime deadlineUtc) {
    final left = deadlineUtc.difference(DateTime.now().toUtc());
    return left.isNegative ? 0 : left.inMilliseconds ~/ 1000 + 1;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(championRoundStartedStreamProvider, (_, n) {
      final v = n.valueOrNull;
      if (v != null) _onRoundStarted(v);
    });
    ref.listen(championRoundResolvedStreamProvider, (_, n) {
      final v = n.valueOrNull;
      if (v != null) _onRoundResolved(v);
    });
    ref.listen(championMatchEndedStreamProvider, (_, n) {
      final v = n.valueOrNull;
      if (v != null) _onMatchEnded(v);
    });
    ref.listen(championDuelStartedStreamProvider, (_, n) {
      final v = n.valueOrNull;
      if (v != null) _onDuelStarted(v);
    });
    ref.listen(championDuelResolvedStreamProvider, (_, n) {
      final v = n.valueOrNull;
      if (v != null) _onDuelResolved(v);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF160B2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Champion vs Tier — LIVE'),
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_ended != null) {
      return Padding(
          padding: const EdgeInsets.all(20), child: _EndedView(ended: _ended!));
    }
    // A duelist gets the focused duel view; everyone else follows the round.
    final duel = _duel;
    if (duel != null && _amInDuel(duel)) {
      return Padding(
          padding: const EdgeInsets.all(20), child: _buildDuel(duel));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (duel != null) _spectatorDuelBanner(duel),
          if (_round != null) _buildRound(_round!) else const _WaitingView(),
          if (_amIChampion && _duel == null && _round != null) ...[
            const SizedBox(height: 20),
            _championControls(),
          ],
          const SizedBox(height: 20),
          _EliminationCam(gameEventId: widget.gameEventId),
        ],
      ),
    );
  }

  Widget _championControls() {
    final canDuel = _duelsRemaining > 0 && !_startingDuel;
    return Column(
      children: [
        const Divider(color: Colors.white12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Champion powers',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w700)),
            Text('$_duelsRemaining duel${_duelsRemaining == 1 ? '' : 's'} left',
                style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: canDuel ? _openDuelPicker : null,
            icon: _startingDuel
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sports_kabaddi_rounded),
            label: Text(_duelsRemaining > 0
                ? 'Call out a challenger'
                : 'No duels remaining'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFCD34D),
              side: const BorderSide(color: Color(0xFFFCD34D)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _spectatorDuelBanner(ChampionDuelStartedDto duel) {
    final resolved = _duelResolved;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCD34D).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_kabaddi_rounded, color: Color(0xFFFCD34D)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              resolved == null
                  ? '⚔️ The Champion called out a challenger — duel in progress!'
                  : (resolved.championAlive
                      ? 'The Champion won the duel and holds the crown.'
                      : 'The challenger dethroned the Champion!'),
              style: const TextStyle(
                  color: Color(0xFFFDE68A), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuel(ChampionDuelStartedDto duel) {
    final resolved = _duelResolved;
    final seconds = _secondsLeft(duel.deadlineUtc);
    final amChampion = _playerId == duel.championPlayerId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_kabaddi_rounded, color: Color(0xFFFCD34D)),
            const SizedBox(width: 8),
            Text(
                amChampion
                    ? 'Your duel — defend the crown!'
                    : 'Duel! Beat the Champion!',
                style: const TextStyle(
                    color: Color(0xFFFCD34D),
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (seconds / 12).clamp(0.0, 1.0),
          backgroundColor: Colors.white10,
          color:
              seconds <= 3 ? const Color(0xFFEF4444) : const Color(0xFFFCD34D),
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text('${seconds}s',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 24),
        Text(duel.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.3)),
        const SizedBox(height: 28),
        ...duel.options.map((o) => _answerTile(
              o,
              selectedId: _duelSelectedOptionId,
              correctId: resolved?.correctOptionId,
              onTap: () => _submitDuel(o.optionId),
            )),
        if (resolved != null) ...[
          const SizedBox(height: 16),
          Text(
            resolved.winnerPlayerId == _playerId
                ? 'You won the duel! 🎉'
                : 'You lost the duel — eliminated.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  Widget _buildRound(ChampionRoundStartedDto round) {
    final resolved = _lastResolved;
    final seconds = _secondsLeft(round.deadlineUtc);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Round ${round.roundNumber}',
                style: const TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w700)),
            Text('${round.aliveCount} alive · 🏆 ${round.jackpotPool}',
                style: const TextStyle(color: Color(0xFFFCD34D))),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (seconds / 12).clamp(0.0, 1.0),
          backgroundColor: Colors.white10,
          color:
              seconds <= 3 ? const Color(0xFFEF4444) : const Color(0xFFA855F7),
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text('${seconds}s',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 24),
        Text(round.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.3)),
        const SizedBox(height: 28),
        ...round.options.map((o) => _answerTile(
              o,
              selectedId: _selectedOptionId,
              correctId: resolved?.correctOptionId,
              onTap: () => _submitRound(o.optionId),
            )),
        if (resolved != null) ...[
          const SizedBox(height: 16),
          Text(
            resolved.eliminatedPlayerIds.isEmpty
                ? 'Everyone survives! Jackpot 🏆 ${resolved.jackpotPool}'
                : '${resolved.eliminatedPlayerIds.length} eliminated · '
                    '${resolved.survivorsRemaining} remain · 🏆 ${resolved.jackpotPool}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ],
    );
  }

  /// Shared answer tile for both rounds and duels. Locks once an answer is
  /// chosen or the correct option is revealed.
  Widget _answerTile(
    ChampionRoundOption o, {
    required String? selectedId,
    required String? correctId,
    required VoidCallback onTap,
  }) {
    final selected = selectedId == o.optionId;
    final revealed = correctId != null;
    final isCorrect = revealed && o.optionId == correctId;
    final isWrongPick = revealed && selected && !isCorrect;

    Color bg = Colors.white10;
    Color border = Colors.white24;
    if (isCorrect) {
      bg = const Color(0xFF10B981).withValues(alpha: 0.25);
      border = const Color(0xFF10B981);
    } else if (isWrongPick) {
      bg = const Color(0xFFEF4444).withValues(alpha: 0.22);
      border = const Color(0xFFEF4444);
    } else if (selected) {
      bg = const Color(0xFFA855F7).withValues(alpha: 0.30);
      border = const Color(0xFFA855F7);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: (revealed || selectedId != null) ? null : onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Text(o.text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class _DuelPicker extends StatelessWidget {
  final List<ChampionParticipant> challengers;
  const _DuelPicker({required this.challengers});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Call out a challenger',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: challengers.length,
              itemBuilder: (ctx, i) {
                final c = challengers[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6D28D9),
                    backgroundImage:
                        (c.avatarUrl != null && c.avatarUrl!.isNotEmpty)
                            ? NetworkImage(c.avatarUrl!)
                            : null,
                    child: (c.avatarUrl == null || c.avatarUrl!.isEmpty)
                        ? Text(
                            c.displayName.isNotEmpty
                                ? c.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white))
                        : null,
                  ),
                  title: Text(c.displayName,
                      style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.sports_kabaddi_rounded,
                      color: Color(0xFFFCD34D)),
                  onTap: () => Navigator.of(ctx).pop(c),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Elimination cam. Everyone sees the live alive-count and jackpot; only
/// premium-pass holders get the running feed of who just got knocked out.
/// Free viewers get a locked upsell teaser instead.
class _EliminationCam extends ConsumerWidget {
  final String gameEventId;
  const _EliminationCam({required this.gameEventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(championSpectatorProvider(gameEventId));
    final view = async.valueOrNull;
    if (view == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.videocam_rounded,
                  color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 8),
              const Text('Elimination Cam',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              if (view.isPremium)
                const _PremiumBadge()
              else
                const Icon(Icons.lock_rounded, color: Colors.white38, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          if (view.isPremium) _feed(view) else _upsell(view),
        ],
      ),
    );
  }

  Widget _feed(ChampionSpectatorView view) {
    if (view.eliminationFeed.isEmpty) {
      return const Text('No eliminations yet — the mob is holding strong.',
          style: TextStyle(color: Colors.white54, fontSize: 13));
    }
    // Newest first.
    final feed = [...view.eliminationFeed]
      ..sort((a, b) => b.eliminatedAtUtc.compareTo(a.eliminatedAtUtc));
    return Column(
      children: [
        for (final e in feed.take(8))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                    e.wasChampion
                        ? Icons.emoji_events_rounded
                        : Icons.person_off_rounded,
                    color: e.wasChampion
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFFEF4444),
                    size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.wasChampion
                        ? '${e.handle} — the Champion fell!'
                        : e.handle,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                if (e.finalRank != null)
                  Text('#${e.finalRank}',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _upsell(ChampionSpectatorView view) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${view.aliveCount} still alive · 🏆 ${view.jackpotPool}',
            style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 13)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFA855F7).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA855F7)),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Color(0xFFC4B5FD), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Premium: watch every elimination as it happens, live.',
                  style: TextStyle(color: Color(0xFFDDD6FE), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFCD34D).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('PREMIUM',
          style: TextStyle(
              color: Color(0xFFFCD34D),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5)),
    );
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded,
              color: Color(0xFFFCD34D), size: 48),
          SizedBox(height: 16),
          Text('Waiting for the next round…',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          SizedBox(height: 8),
          Text('Answer correctly to survive. One wrong answer and you\'re out.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}

class _EndedView extends StatelessWidget {
  final ChampionMatchEndedDto ended;
  const _EndedView({required this.ended});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: Color(0xFFFCD34D), size: 64),
          const SizedBox(height: 20),
          Text(
            ended.championDefended
                ? 'The Champion defended the crown!'
                : 'A new Champion is crowned!',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            'Jackpot awarded: 🏆 ${ended.jackpotAwarded}\n${ended.roundsPlayed} rounds played',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Back to leaderboard'),
          ),
        ],
      ),
    );
  }
}
