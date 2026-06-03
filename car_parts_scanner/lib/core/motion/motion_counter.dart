import 'package:flutter/material.dart';

class MotionCounter extends StatelessWidget {
  final num value;
  final String prefix;
  final String suffix;
  final int decimals;
  final TextStyle style;
  final Duration duration;

  const MotionCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
    required this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Text(
        '$prefix${value.toStringAsFixed(decimals)}$suffix',
        style: style,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Text(
          '$prefix${val.toStringAsFixed(decimals)}$suffix',
          style: style,
        );
      },
    );
  }
}
