import 'package:flutter/material.dart';

// FR-6: cham lat the animation 3D (~300ms). isFlipped duoc dieu khien tu ben ngoai (session state).
class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool isFlipped;
  final VoidCallback? onTap;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    required this.isFlipped,
    this.onTap,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.isFlipped ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFlipped != widget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double angle = _controller.value * 3.14159265;
          final bool isBackVisible = angle > 3.14159265 / 2;
          final double displayAngle = isBackVisible ? angle - 3.14159265 : angle;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(displayAngle),
            child: isBackVisible ? widget.back : widget.front,
          );
        },
      ),
    );
  }
}
