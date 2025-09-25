import 'package:flutter/material.dart';
import '../../../game/models/versus_models.dart';

class VersusBanner extends StatelessWidget {
  final VersusConfig config;
  final double height;
  final EdgeInsets padding;

  const VersusBanner({
    super.key,
    required this.config,
    this.height = 160,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final left = config.left;
    final right = config.right;

    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (left.color ?? Colors.blueGrey).withOpacity(0.25),
            (right.color ?? Colors.pink).withOpacity(0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(child: _SideInfo(participant: left, alignEnd: true)),
          _VsBadge(mode: config.mode),
          Expanded(child: _SideInfo(participant: right)),
        ],
      ),
    );
  }
}

class _SideInfo extends StatelessWidget {
  final Participant participant;
  final bool alignEnd;

  const _SideInfo({required this.participant, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignEnd ? TextAlign.right : TextAlign.left;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: align,
      children: [
        _AvatarOrLogo(url: participant.avatarUrl, fallbackChar: participant.displayName.isNotEmpty ? participant.displayName[0] : '?', color: participant.color),
        const SizedBox(height: 8),
        Text(
          participant.displayName,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (participant.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            participant.subtitle!,
            textAlign: textAlign,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
            ),
          ),
        ],
        if (participant.isTeam) ...[
          const SizedBox(height: 6),
          _MemberStack(members: participant.members, alignEnd: alignEnd),
        ],
      ],
    );
  }
}

class _AvatarOrLogo extends StatelessWidget {
  final String? url;
  final String fallbackChar;
  final Color? color;
  const _AvatarOrLogo({this.url, required this.fallbackChar, this.color});

  @override
  Widget build(BuildContext context) {
    final bg = (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.2);
    return CircleAvatar(
      radius: 28,
      backgroundColor: bg,
      backgroundImage: url != null ? NetworkImage(url!) : null,
      child: url == null
          ? Text(
        fallbackChar.toUpperCase(),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
      )
          : null,
    );
  }
}

class _MemberStack extends StatelessWidget {
  final List<Member> members;
  final bool alignEnd;
  const _MemberStack({required this.members, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    final children = members.take(5).toList();
    return SizedBox(
      height: 38,
      child: Stack(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          for (int i = 0; i < children.length; i++)
            Positioned(
              left: alignEnd ? null : i * 24.0,
              right: alignEnd ? i * 24.0 : null,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                backgroundImage: children[i].avatarUrl != null
                    ? NetworkImage(children[i].avatarUrl!)
                    : null,
                child: children[i].avatarUrl == null
                    ? Text(children[i].name[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold))
                    : null,
              ),
            ),
          if (members.length > children.length)
            Positioned(
              left: alignEnd ? null : children.length * 24.0,
              right: alignEnd ? children.length * 24.0 : null,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: Text('+${members.length - children.length}'),
              ),
            ),
        ],
      ),
    );
  }
}

class _VsBadge extends StatelessWidget {
  final VersusMode mode;
  const _VsBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    final label = switch (mode) {
      VersusMode.oneVone => 'VS',
      VersusMode.teamVteam => 'TEAM VS',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
