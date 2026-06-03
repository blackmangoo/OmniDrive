import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TappableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDownTo;
  final Duration duration;

  const TappableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDownTo = 0.97,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<TappableScale> createState() => _TappableScaleState();
}

class _TappableScaleState extends State<TappableScale> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(begin: 1.0, end: widget.scaleDownTo).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnims = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      onTapDown: (_) {
        if (!disableAnims && widget.onTap != null) {
          _controller.forward();
        }
      },
      onTapUp: (_) {
        if (!disableAnims && widget.onTap != null) {
          _controller.reverse();
        }
      },
      onTapCancel: () {
        if (!disableAnims && widget.onTap != null) {
          _controller.reverse();
        }
      },
      onTap: () {
        if (widget.onTap != null) {
          HapticFeedback.lightImpact();
          widget.onTap!();
        }
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: disableAnims ? 1.0 : _scale.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
