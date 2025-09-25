import 'package:flutter/material.dart';
import '../models/card_overlay_action.dart';

class InteractiveOverlay extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  /// Preferred: matches DepthCardConfig.overlayActions
  final List<CardOverlayAction>? overlayActions;

  /// Back-compat: older call sites
  @Deprecated('Use overlayActions instead.')
  final List<CardOverlayAction>? actions;

  final double width;
  final double height;

  const InteractiveOverlay({
    super.key,
    required this.text,
    this.onTap,
    this.overlayActions,
    @Deprecated('Use overlayActions instead.') this.actions,
    required this.width,
    required this.height,
  });

  List<CardOverlayAction> get _effectiveActions =>
      (overlayActions ?? actions) ?? const <CardOverlayAction>[];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                if (_effectiveActions.isNotEmpty)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _effectiveActions.map((a) {
                        return ActionChip(
                          // NOTE: a.icon appears non-nullable in your project
                          avatar: Icon(a.icon, size: 18, color: Colors.white),
                          // If your CardOverlayAction uses 'title' or 'name', change 'text' below accordingly.
                          label: Text(
                            a.name ?? a.title ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                          onPressed: a.onPressed,
                          backgroundColor: Colors.black.withOpacity(0.30),
                          shape: StadiumBorder(
                            side: BorderSide(color: Colors.white.withOpacity(0.25)),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
