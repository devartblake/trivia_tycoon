import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dto/champion_round_events.dart';
import '../../game/providers/core_providers.dart' show apiServiceProvider;
import '../../game/providers/hub_providers.dart';

/// Live Champion vs Tier match screen. Joins the event's realtime group, shows
/// the current round question with a countdown, submits the tapped answer, and
/// renders round-resolved / match-ended feedback.
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
  String? _selectedOptionId;
  bool _submitting = false;
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Join the realtime group and replay the in-progress state so a client
    // entering mid-match sees the current round/duel without waiting.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref
            .read(notificationHubProvider)
            .joinGameEvent(widget.gameEventId);
      } catch (_) {
        // Not connected yet — the stream listeners still catch rounds once it is.
      }
      await _replayFromSnapshot();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Replay-on-join: seed the current open round from the backend snapshot so
  /// a mid-match arrival renders immediately. A live broadcast for a newer
  /// round always supersedes this.
  Future<void> _replayFromSnapshot() async {
    final snap =
        await ref.read(apiServiceProvider).getLiveSnapshot(widget.gameEventId);
    if (!mounted || snap == null || _round != null || _ended != null) return;
    final round = snap.currentRound;
    if (round != null) _onRoundStarted(round);
  }

  bool _isForThisEvent(String eventId) => eventId == widget.gameEventId;

  void _onRoundStarted(ChampionRoundStartedDto r) {
    if (!_isForThisEvent(r.gameEventId)) return;
    setState(() {
      _round = r;
      _lastResolved = null;
      _selectedOptionId = null;
    });
    _startTicker(r.deadlineUtc);
  }

  void _onRoundResolved(ChampionRoundResolvedDto r) {
    if (!_isForThisEvent(r.gameEventId)) return;
    _ticker?.cancel();
    setState(() => _lastResolved = r);
  }

  void _onMatchEnded(ChampionMatchEndedDto r) {
    if (!_isForThisEvent(r.gameEventId)) return;
    _ticker?.cancel();
    setState(() => _ended = r);
  }

  void _startTicker(DateTime deadlineUtc) {
    _ticker?.cancel();
    void tick() {
      final left = deadlineUtc.difference(DateTime.now().toUtc());
      setState(() => _remaining = left.isNegative ? Duration.zero : left);
    }

    tick();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => tick());
  }

  Future<void> _submit(String optionId) async {
    if (_submitting || _selectedOptionId != null) return;
    setState(() {
      _selectedOptionId = optionId;
      _submitting = true;
    });
    try {
      await ref.read(apiServiceProvider).submitRoundAnswer(
            gameEventId: widget.gameEventId,
            optionId: optionId,
          );
    } catch (_) {
      // Leave the selection; the round will resolve regardless.
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bridge the broadcast streams into local state.
    ref.listen(championRoundStartedStreamProvider, (_, next) {
      final v = next.valueOrNull;
      if (v != null) _onRoundStarted(v);
    });
    ref.listen(championRoundResolvedStreamProvider, (_, next) {
      final v = next.valueOrNull;
      if (v != null) _onRoundResolved(v);
    });
    ref.listen(championMatchEndedStreamProvider, (_, next) {
      final v = next.valueOrNull;
      if (v != null) _onMatchEnded(v);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF160B2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Champion vs Tier — LIVE'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _ended != null
              ? _EndedView(ended: _ended!)
              : _round == null
                  ? const _WaitingView()
                  : _buildRound(_round!),
        ),
      ),
    );
  }

  Widget _buildRound(ChampionRoundStartedDto round) {
    final resolved = _lastResolved;
    final seconds = _remaining.inMilliseconds / 1000.0;
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
          color: seconds <= 3 ? const Color(0xFFEF4444) : const Color(0xFFA855F7),
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text('${seconds.ceil()}s',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 24),
        Text(
          round.prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 28),
        ...round.options.map((o) => _optionTile(o, resolved)),
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

  Widget _optionTile(ChampionRoundOption o, ChampionRoundResolvedDto? resolved) {
    final selected = _selectedOptionId == o.optionId;
    final revealed = resolved != null;
    final isCorrect = revealed && o.optionId == resolved.correctOptionId;
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
          onTap: (revealed || _selectedOptionId != null)
              ? null
              : () => _submit(o.optionId),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Text(
              o.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView();
  @override
  Widget build(BuildContext context) {
    return const Center(
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
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
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
