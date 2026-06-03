import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StaggeredEntrance extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delayStep;

  const StaggeredEntrance({
    super.key,
    required this.child,
    required this.index,
    this.delayStep = const Duration(milliseconds: 40),
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return child;
    }

    return child
        .animate(delay: delayStep * index)
        .fadeIn(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.08,
          end: 0.0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
  }
}
