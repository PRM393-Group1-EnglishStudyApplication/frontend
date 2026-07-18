import 'package:flutter/material.dart';

enum SwipeDirection { left, right }

// FR-7: vuot phai/trai voi hieu ung nghieng the + overlay mau theo khoang keo;
// tha qua nguong -> the bay ra; chua qua nguong -> spring ve giua.
// Dung Key rieng cho tung the (vd ValueKey(vocabularyId)) de State tu reset khi doi the, khong can
// rebuild lai deck moi frame (NFR-1: chi AnimatedBuilder tren the dang keo).
class SwipeableCard extends StatefulWidget {
  final Widget child;
  final ValueChanged<SwipeDirection>? onSwiped;
  final VoidCallback? onTap;
  final bool enabled;

  const SwipeableCard({
    super.key,
    required this.child,
    this.onSwiped,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard> with SingleTickerProviderStateMixin {
  static const double _swipeThreshold = 110;
  static const double _maxRotationRadians = 0.35;

  Offset _dragOffset = Offset.zero;
  late final AnimationController _flingController;
  Animation<Offset>? _flingAnimation;
  SwipeDirection? _pendingDirection;

  @override
  void initState() {
    super.initState();
    _flingController = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
      ..addListener(_onFlingTick)
      ..addStatusListener(_onFlingStatusChanged);
  }

  @override
  void dispose() {
    _flingController.dispose();
    super.dispose();
  }

  void _onFlingTick() {
    final animation = _flingAnimation;
    if (animation == null) {
      return;
    }
    setState(() {
      _dragOffset = animation.value;
    });
  }

  void _onFlingStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    final direction = _pendingDirection;
    _pendingDirection = null;
    if (direction != null) {
      widget.onSwiped?.call(direction);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragOffset.dx.abs() > _swipeThreshold) {
      _flingAway(_dragOffset.dx > 0 ? SwipeDirection.right : SwipeDirection.left);
    } else {
      _springBack();
    }
  }

  void _flingAway(SwipeDirection direction) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double endX = direction == SwipeDirection.right ? screenWidth * 1.2 : -screenWidth * 1.2;
    _pendingDirection = direction;
    _flingAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(endX, _dragOffset.dy),
    ).animate(CurvedAnimation(parent: _flingController, curve: Curves.easeOut));
    _flingController.forward(from: 0);
  }

  void _springBack() {
    _flingAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _flingController, curve: Curves.elasticOut));
    _flingController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_dragOffset.dx / _swipeThreshold).clamp(-1.0, 1.0);
    final double angle = (_dragOffset.dx / 300).clamp(-_maxRotationRadians, _maxRotationRadians);
    final double overlayOpacity = progress.abs().clamp(0.0, 1.0) * 0.35;
    final bool isRight = progress > 0;

    return GestureDetector(
      onTap: widget.onTap,
      onPanUpdate: widget.enabled && !_flingController.isAnimating ? _onPanUpdate : null,
      onPanEnd: widget.enabled && !_flingController.isAnimating ? _onPanEnd : null,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: angle,
          child: Stack(
            children: [
              widget.child,
              if (overlayOpacity > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: (isRight ? Colors.green : Colors.orange).withValues(alpha: overlayOpacity),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      alignment: isRight ? Alignment.centerLeft : Alignment.centerRight,
                      padding: const EdgeInsets.all(20),
                      child: Icon(
                        isRight ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
