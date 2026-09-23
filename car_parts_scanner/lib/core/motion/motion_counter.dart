import 'package:flutter/material.dart';

/// Renders a number, animating only when the value genuinely changes.
///
/// The previous version passed `Tween(begin: 0.0, end: value)`, so every price,
/// order total and KPI counted up from zero whenever its widget was recreated —
/// which happens on every pull-to-refresh and every time a list item is
/// scrolled back into view. Money visibly rolling like a slot machine each time
/// you refreshed your cart is not something a product ships.
///
/// Setting `begin == end` on first build means the number appears immediately;
/// [TweenAnimationBuilder] then animates from the current value only when `end`
/// changes while the widget is alive.
///
/// Digits are rendered with tabular figures so the line does not shift width
/// mid-transition.
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
    this.duration = const Duration(milliseconds: 250),
  });

  String _format(double v) =>
      '$prefix${v.toStringAsFixed(decimals)}$suffix';

  @override
  Widget build(BuildContext context) {
    final target = value.toDouble();
    final textStyle = _withTabularFigures(style);

    if (MediaQuery.of(context).disableAnimations) {
      return Text(_format(target), style: textStyle);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: target, end: target),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, animated, child) =>
          Text(_format(animated), style: textStyle),
    );
  }

  static TextStyle _withTabularFigures(TextStyle style) {
    final features = style.fontFeatures ?? const <FontFeature>[];
    if (features.contains(const FontFeature.tabularFigures())) return style;
    return style.copyWith(
      fontFeatures: [...features, const FontFeature.tabularFigures()],
    );
  }
}
