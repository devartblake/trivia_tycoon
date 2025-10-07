library;

import 'package:flutter/material.dart';

class ExpansionTileCard extends StatefulWidget {
  const ExpansionTileCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.onExpansionChanged,
    this.children = const <Widget>[],
    this.trailing,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.elevation = 2.0,
    this.initialElevation = 0.0,
    this.initiallyExpanded = false,
    this.initialPadding = EdgeInsets.zero,
    this.finalPadding = const EdgeInsets.only(bottom: 6.0),
    this.contentPadding,
    this.baseColor,
    this.expandedColor,
    this.expandedTextColor,
    this.duration = const Duration(milliseconds: 200),
    this.elevationCurve = Curves.easeOut,
    this.heightFactorCurve = Curves.easeIn,
    this.turnsCurve = Curves.easeIn,
    this.colorCurve = Curves.easeIn,
    this.paddingCurve = Curves.easeIn,
    this.isThreeLine = false,
    this.shadowColor = const Color(0xffaaaaaa),
    this.animateTrailing = false,
    this.maintainState = false,   // NEW: keep children in the tree when collapsed
    this.dense = false,           // NEW: opt-in denser ListTile for long lists
  });

  final bool isThreeLine;
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final ValueChanged<bool>? onExpansionChanged;
  final List<Widget> children;
  final Widget? trailing;
  final bool animateTrailing;

  final BorderRadiusGeometry borderRadius;
  final double elevation;
  final double initialElevation;
  final Color shadowColor;

  final bool initiallyExpanded;

  final EdgeInsetsGeometry initialPadding;
  final EdgeInsetsGeometry finalPadding;
  final EdgeInsetsGeometry? contentPadding;

  final Color? baseColor;
  final Color? expandedColor;
  final Color? expandedTextColor;

  final Duration duration;
  final Curve elevationCurve;
  final Curve heightFactorCurve;
  final Curve turnsCurve;
  final Curve colorCurve;
  final Curve paddingCurve;

  final bool maintainState; // NEW
  final bool dense;         // NEW

  @override
  ExpansionTileCardState createState() => ExpansionTileCardState();
}

class ExpansionTileCardState extends State<ExpansionTileCard>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _halfTween = Tween<double>(begin: 0.0, end: 0.5);

  // Color tweens
  final ColorTween _headerColorTween = ColorTween();
  final ColorTween _iconColorTween = ColorTween();
  final ColorTween _materialColorTween = ColorTween();

  // Safer: geometry tween (works with any EdgeInsetsGeometry)
  late final EdgeInsetsGeometryTween _edgeInsetsTween;

  late final Animatable<double> _elevationTween;
  late final Animatable<double> _heightFactorTween;
  late final Animatable<double> _turnsTween;
  late final Animatable<double> _colorTween;
  late final Animatable<double> _paddingTween;

  late final AnimationController _controller;
  late final Animation<double> _iconTurns;
  late final Animation<double> _heightFactor;
  late final Animation<double> _elevation;
  late final Animation<Color?> _headerColor;
  late final Animation<Color?> _iconColor;
  late final Animation<Color?> _materialColor;
  late final Animation<EdgeInsetsGeometry> _padding;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    _edgeInsetsTween = EdgeInsetsGeometryTween(
      begin: widget.initialPadding,
      end: widget.finalPadding,
    );
    _elevationTween = CurveTween(curve: widget.elevationCurve);
    _heightFactorTween = CurveTween(curve: widget.heightFactorCurve);
    _colorTween = CurveTween(curve: widget.colorCurve);
    _turnsTween = CurveTween(curve: widget.turnsCurve);
    _paddingTween = CurveTween(curve: widget.paddingCurve);

    _controller = AnimationController(duration: widget.duration, vsync: this);

    _heightFactor = _controller.drive(_heightFactorTween);
    _iconTurns = _controller.drive(_halfTween.chain(_turnsTween));
    _headerColor = _controller.drive(_headerColorTween.chain(_colorTween));
    _materialColor = _controller.drive(_materialColorTween.chain(_colorTween));
    _iconColor = _controller.drive(_iconColorTween.chain(_colorTween));
    _elevation = _controller.drive(
      Tween<double>(begin: widget.initialElevation, end: widget.elevation)
          .chain(_elevationTween),
    );
    _padding = _controller.drive(_edgeInsetsTween.chain(_paddingTween));

    _isExpanded = (PageStorage.of(context).readState(context) as bool?) ??
        widget.initiallyExpanded;
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setExpansion(bool expand) {
    if (expand == _isExpanded) return;

    setState(() {
      _isExpanded = expand;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      PageStorage.of(context).writeState(context, _isExpanded);
    });

    widget.onExpansionChanged?.call(_isExpanded);
  }

  void expand() => _setExpansion(true);
  void collapse() => _setExpansion(false);
  void toggleExpansion() => _setExpansion(!_isExpanded);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    _headerColorTween
      ..begin = theme.textTheme.titleMedium?.color
      ..end = widget.expandedTextColor ?? theme.colorScheme.secondary;
    _iconColorTween
      ..begin = theme.unselectedWidgetColor
      ..end = widget.expandedTextColor ?? theme.colorScheme.secondary;
    _materialColorTween
      ..begin = widget.baseColor ?? theme.canvasColor
      ..end = widget.expandedColor ?? theme.cardColor;
  }

  // Only rebuild what needs animation
  Widget _animatedTile(BuildContext context, Widget? child) {
    final trailing = widget.trailing ??
        const Icon(Icons.expand_more, semanticLabel: 'Expand');

    return Padding(
      padding: _padding.value, // animated padding
      child: Material(
        type: MaterialType.card,
        color: _materialColor.value,
        borderRadius: widget.borderRadius,
        elevation: _elevation.value,
        shadowColor: widget.shadowColor,
        clipBehavior: Clip.antiAlias, // better clipping for rounded corners
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            InkWell(
              customBorder: RoundedRectangleBorder(borderRadius: widget.borderRadius),
              onTap: toggleExpansion,
              child: ListTileTheme.merge(
                iconColor: _iconColor.value,
                textColor: _headerColor.value,
                child: ListTile(
                  dense: widget.dense,
                  isThreeLine: widget.isThreeLine,
                  contentPadding: widget.contentPadding,
                  leading: widget.leading,
                  title: widget.title,
                  subtitle: widget.subtitle,
                  trailing: RotationTransition(
                    turns: (widget.trailing == null || widget.animateTrailing)
                        ? _iconTurns
                        : const AlwaysStoppedAnimation(0),
                    child: trailing,
                  ),
                ),
              ),
            ),
            // Children: kept offstage when collapsed; still kept alive if maintainState is true
            ClipRect(
              child: Align(
                heightFactor: _heightFactor.value,
                alignment: Alignment.topCenter,
                child: widget.maintainState
                    ? TickerMode(
                  enabled: _isExpanded,
                  child: Offstage(
                    offstage: !_isExpanded,
                    child: child,
                  ),
                )
                    : child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool closed = !_isExpanded && _controller.isDismissed;

    // We only build the children column when expanded, unless maintainState is requested
    final Widget? child = (closed && !widget.maintainState)
        ? null
        : Column(children: widget.children);

    return AnimatedBuilder(
      animation: _controller.view,
      builder: _animatedTile,
      child: child,
    );
  }
}
