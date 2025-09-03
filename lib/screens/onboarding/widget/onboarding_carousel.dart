import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../ui_components/carousel/side.dart';
import '../../../ui_components/carousel/sun_moon.dart';
import '../../../ui_components/carousel/gooey_edge.dart';
import '../../../ui_components/carousel/gooey_edge_clipper.dart';

class OnboardingCarousel extends StatefulWidget {
  final List<Widget> children;

  const OnboardingCarousel({super.key, required this.children});

  @override
  OnboardingCarouselState createState() => OnboardingCarouselState();
}

class OnboardingCarouselState extends State<OnboardingCarousel>
    with SingleTickerProviderStateMixin {
    late Ticker _ticker;
    final DragState _dragState = DragState();
    final GooeyEdge _edge = GooeyEdge(count: 25);
    final GlobalKey _carouselKey = GlobalKey();

  @override
  void initState() {
    _ticker = createTicker(_tick)..start();
    super.initState();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration duration) {
    _edge.tick(duration);
    // TODO: This tick could be more efficient, could use an AnimatedBuilder for the GooeyEdge,
    // and just pass the index into the SunMoon widget, which can tick internally when index changes
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final int totalChildren = widget.children.length;

    return GestureDetector(
        key: _carouselKey,
        onPanDown: (details) => _handlePanDown(details, _getSize()),
        onPanUpdate: (details) => _handlePanUpdate(details, _getSize()),
        onPanEnd: (details) => _handlePanEnd(details, _getSize()),
        child: Stack(
          children: <Widget>[
            widget.children[_dragState._currentIndex % totalChildren],
            _dragState._dragIndex == null
                ? SizedBox()
                : ClipPath(
                    clipBehavior: Clip.hardEdge,
                    clipper: GooeyEdgeClipper(_edge, margin: 10.0),
                    child: widget.children[_dragState._dragIndex! % totalChildren],
                  ),
            _buildSunAndMoon(),
          ],
        ));
  }

  Size _getSize() {
    final RenderBox? box =
        _carouselKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size ?? Size.zero;
  }

  void _handlePanDown(DragDownDetails details, Size size) {
    if (_dragState._dragIndex != null && _dragState._dragCompleted) {
      _dragState._currentIndex = _dragState._dragIndex!;
    }
    _dragState._dragIndex = null;
    _dragState._dragOffset = details.localPosition;
    _dragState._dragCompleted = false;
    _dragState._dragDirection = 0;

    _edge.farEdgeTension = 0.0;
    _edge.edgeTension = 0.01;
    _edge.reset();
  }

  void _handlePanEnd(DragEndDetails details, Size size) {
    _edge.applyTouchOffset();
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    double dx = details.localPosition.dx - _dragState._dragOffset.dx;

    if (!_isSwipeActive(dx)) {
      return;
    }
    if (_isSwipeComplete(dx, size.width)) {
      return;
    }

    if (_dragState._dragDirection == -1) {
      dx = size.width + dx;
    }
    _edge.applyTouchOffset(Offset(dx, details.localPosition.dy), size);
  }

  bool _isSwipeActive(double dx) {
    // check if a swipe is just starting:
    if (_dragState._dragDirection == 0.0 && dx.abs() > 20.0) {
      _dragState._dragDirection = dx.sign;
      _edge.side = _dragState._dragDirection == 1.0 ? Side.left : Side.right;
      setState(() {
        _dragState._dragIndex = _dragState._currentIndex - _dragState._dragDirection.toInt();
      });
    }
    return _dragState._dragDirection != 0.0;
  }

  bool _isSwipeComplete(double dx, double width) {
    if (_dragState._dragDirection == 0.0) {
      return false;
    } // haven't started
    if (_dragState._dragCompleted) {
      return true;
    } // already done

    // check if swipe is just completed:
    double availW = _dragState._dragOffset.dx;
    if (_dragState._dragDirection == 1) {
      availW = width - availW;
    }
    double ratio = dx * _dragState._dragDirection / availW;

    if (ratio > 0.8 && availW / width > 0.5) {
      _dragState._dragCompleted = true;
      _edge.farEdgeTension = 0.01;
      _edge.edgeTension = 0.0;
      _edge.applyTouchOffset();
    }
    return _dragState._dragCompleted;
  }
  
  Widget _buildDragLayer(int totalChildren) {
    widget.children[_dragState._currentIndex % totalChildren];
    if (_dragState._dragIndex == null) return const SizedBox();
    return ClipPath(
      clipBehavior: Clip.hardEdge,
      clipper: GooeyEdgeClipper(_edge, margin: 10.0),
      child: widget.children[_dragState._dragIndex! % totalChildren],
    );
  }
  Widget _buildSunAndMoon() {
    return SunAndMoon(
      index: _dragState._dragIndex ?? _dragState._currentIndex,
      isDragComplete: _dragState._dragCompleted,
    );
  }
}

class DragState {
  int _currentIndex = 0;
  int? _dragIndex;
  Offset _dragOffset = Offset.zero;
  double _dragDirection = 0;
  bool _dragCompleted = false;
  void reset(Offset dragOffset) {
    _dragIndex = null;
    _dragOffset = dragOffset;
    _dragCompleted = false;
    _dragDirection = 0;
  }
  bool isSwipeActive(double dx, GooeyEdge edge) {
    if (_dragDirection == 0.0 && dx.abs() > 20.0) {
      _dragDirection = dx.sign;
      edge.side =
          _dragDirection == 1.0 ? Side.left : Side.right; // Use edge parameter
      return true;
    }
    return _dragDirection != 0.0;
  }
  bool isSwipeComplete(
      double dx, double width, double threshold, bool looping) {
    if (_dragDirection == 0.0 || _dragCompleted) return _dragCompleted;
    final double availableWidth =
        _dragDirection == 1 ? width - _dragOffset.dx : _dragOffset.dx;
    final double swipeRatio = dx * _dragDirection / availableWidth;
    if (swipeRatio > threshold && availableWidth / width > 0.5) {
      _dragCompleted = true;
      return true;
    }
    return false;
  }
}
