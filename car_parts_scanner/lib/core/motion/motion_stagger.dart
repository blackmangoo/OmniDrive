import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A short fade-in for content appearing on screen.
///
/// Previously this applied `fadeIn` + `slideY` with a delay of `40ms * index`,
/// uncapped. Wrapped around items in `ListView.builder` and
/// `SliverChildBuilderDelegate`, that meant item 20 of a long list waited 800ms
/// before becoming visible, and the whole screen visibly cascaded on every
/// navigation. Content that slides up into place on a data list is decoration;
/// it does not help the user read anything.
///
/// What is left is a brief opacity fade with a hard cap on the delay, so a list
/// settles almost immediately regardless of length.
class StaggeredEntrance extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delayStep;
  final Duration maxDelay;

  const StaggeredEntrance({
    super.key,
    required this.child,
    required this.index,
    this.delayStep = const Duration(milliseconds: 25),
    this.maxDelay = const Duration(milliseconds: 125),
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;

    final stepMs = delayStep.inMilliseconds * index.clamp(0, 32);
    final delay = Duration(
      milliseconds: stepMs > maxDelay.inMilliseconds
          ? maxDelay.inMilliseconds
          : stepMs,
    );

    return child.animate(delay: delay).fadeIn(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
        );
  }
}
