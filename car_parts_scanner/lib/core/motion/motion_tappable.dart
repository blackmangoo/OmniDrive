import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_spacing.dart';

/// A press-scale wrapper for controls that are not Material buttons.
///
/// This is used in place of [InkWell] / [IconButton] across the app, so it has
/// to carry the responsibilities those widgets normally provide. The original
/// version was a bare [GestureDetector], which meant every one of its ~85 call
/// sites was invisible to TalkBack, unreachable by keyboard, had no focus ring,
/// and rendered a disabled control identically to an enabled one — passing
/// `onTap: null` produced a button that looked tappable and silently did
/// nothing.
///
/// It now exposes a button semantic node, dims when disabled, refuses to fire
/// haptics on every single row tap (a light tap on a dense list is noise, not
/// feedback), and pads itself out to a minimum hit target.
///
/// Prefer a real [ElevatedButton], [OutlinedButton], [TextButton] or
/// [IconButton] for anything that is a primary action; reach for this only when
/// a whole card or custom-shaped surface needs to be tappable.
class TappableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDownTo;
  final Duration duration;

  /// Announced to assistive technology. Defaults to the button role; supply this
  /// when the child is icon-only and has no visible text.
  final String? semanticLabel;

  /// Expands the hit area to the platform minimum without changing the visual
  /// size of [child]. Leave null for surfaces that already fill their row.
  final bool enforceMinHitTarget;

  /// Fires a light haptic on activation. Off by default: this widget wraps
  /// dense list rows and cards, where a buzz on every tap is unpleasant.
  final bool hapticFeedback;

  const TappableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDownTo = 0.97,
    this.duration = const Duration(milliseconds: 100),
    this.semanticLabel,
    this.enforceMinHitTarget = false,
    this.hapticFeedback = false,
  });

  @override
  State<TappableScale> createState() => _TappableScaleState();
}

class _TappableScaleState extends State<TappableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  bool get _enabled => widget.onTap != null;

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

  void _press() {
    if (!_enabled) return;
    if (widget.hapticFeedback) HapticFeedback.lightImpact();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnims = MediaQuery.of(context).disableAnimations;

    Widget content = AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: disableAnims || !_enabled ? 1.0 : _scale.value,
        child: child,
      ),
      child: Opacity(
        // A disabled control must not look identical to an enabled one.
        opacity: _enabled ? 1.0 : 0.45,
        child: widget.child,
      ),
    );

    if (widget.enforceMinHitTarget) {
      content = ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.hitTarget,
          minHeight: AppSpacing.hitTarget,
        ),
        child: Center(child: content),
      );
    }

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (_enabled && !disableAnims) _controller.forward();
        },
        onTapUp: (_) {
          if (_enabled && !disableAnims) _controller.reverse();
        },
        onTapCancel: () {
          if (_enabled && !disableAnims) _controller.reverse();
        },
        onTap: _enabled ? _press : null,
        child: content,
      ),
    );
  }
}
