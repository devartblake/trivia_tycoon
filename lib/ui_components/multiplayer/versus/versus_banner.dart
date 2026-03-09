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
            (left.color ?? Colors.blueGrey).withValues(alpha: 0.25),
            (right.color ?? Colors.pink).withValues(alpha: 0.25),
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

    return LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight <= 110;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: align,
            children: [
            _AvatarOrLogo(
            url: participant.avatarUrl,
            fallbackChar:
            participant.displayName.isNotEmpty ? participant.displayName[0] : '?',
            color: participant.color,
            radius: compact ? 22 : 28,
            ),
              SizedBox(height: compact ? 4 : 8),
              Text(
                participant.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: textAlign,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 18 : null,
                ),
              ),
              if (participant.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  participant.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: textAlign,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.8),
                  ),
                ),
              ],
              if (participant.isTeam) ...[
                SizedBox(height: compact ? 4 : 6),
                _MemberStack(
                  members: participant.members,
                  alignEnd: alignEnd,
                  compact: compact,
                ),
              ],
            ],
          );
        },
    );
  }
}

class _AvatarOrLogo extends StatelessWidget {
  final String? url;
  final String fallbackChar;
  final Color? color;
  final double radius;
  const _AvatarOrLogo({
    this.url,
    required this.fallbackChar,
    this.color,
    this.radius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final bg = (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.2);
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      backgroundImage: url != null ? NetworkImage(url!) : null,
      child: url == null
          ? Text(
        fallbackChar.toUpperCase(),
        style: TextStyle(fontSize: radius * 0.78, fontWeight: FontWeight.w900),
      )
          : null,
    );
  }
}

class _MemberStack extends StatelessWidget {
  final List<Member> members;
  final bool alignEnd;
  final bool compact;
  const _MemberStack({
    required this.members,
    this.alignEnd = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarRadius = compact ? 14.0 : 18.0;
    final gap = compact ? 18.0 : 24.0;
    final children = members.take(compact ? 3 : 5).toList();
    return SizedBox(
      height: compact ? 30 : 38,
      child: Stack(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          for (int i = 0; i < children.length; i++)
            Positioned(
              left: alignEnd ? null : i * gap,
              right: alignEnd ? i * gap : null,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                backgroundImage: children[i].avatarUrl != null
                    ? NetworkImage(children[i].avatarUrl!)
                    : null,
                child: children[i].avatarUrl == null
                    ? Text(children[i].name[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 10 : 12,
                    ))
                    : null,
              ),
            ),
          if (members.length > children.length)
            Positioned(
              left: alignEnd ? null : children.length * gap,
              right: alignEnd ? children.length * gap : null,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: Text(
                  '+${members.length - children.length}',
                  style: TextStyle(fontSize: compact ? 9 : 11),
                ),
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
