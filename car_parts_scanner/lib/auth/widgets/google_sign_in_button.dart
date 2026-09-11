import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/motion/motion_tappable.dart';

/// A theme-aware, production-grade button for Google Sign-In in OmniDrive.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'Continue with Google',
  });

  @override
  Widget build(BuildContext context) {
    // Rely strictly on Theme.of(context) to avoid mixing system dispatcher brightness
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E3);
    final textColor = isDark ? const Color(0xFFF5F5F4) : const Color(0xFF1C1917);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TappableScale(
        onTap: isLoading ? null : onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppSpacing.rLg),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GoogleLogo(size: 20),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: AppTypography.label.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Official 4-color Google "G" Emblem rendered via high-precision precomputed vectors.
class GoogleLogo extends StatefulWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 24});

  @override
  State<GoogleLogo> createState() => _GoogleLogoState();
}

class _GoogleLogoState extends State<GoogleLogo> {
  late _GoogleLogoPainter _painter;

  @override
  void initState() {
    super.initState();
    _painter = _GoogleLogoPainter.build(widget.size);
  }

  @override
  void didUpdateWidget(GoogleLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size != widget.size) {
      _painter = _GoogleLogoPainter.build(widget.size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _painter,
      ),
    );
  }
}

/// Zero-allocation painter: all Path and Rect instances are precomputed once,
/// eliminating GC pressure during button interactions and animations.
class _GoogleLogoPainter extends CustomPainter {
  final Path redPath;
  final Path yellowPath;
  final Path greenPath;
  final Path blueArcPath;
  final RRect barRect;

  _GoogleLogoPainter._({
    required this.redPath,
    required this.yellowPath,
    required this.greenPath,
    required this.blueArcPath,
    required this.barRect,
  });

  static final Paint _paint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  factory _GoogleLogoPainter.build(double size) {
    final double radius = size / 2.0;
    final double innerRadius = radius * 0.58;
    final center = Offset(radius, radius);
    final outerRect = Rect.fromCircle(center: center, radius: radius);
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

    // Annular sector path builder without canvas clips
    Path buildWedge(double startAngle, double sweepAngle) {
      final path = Path();
      // Outer arc
      path.arcTo(outerRect, startAngle, sweepAngle, false);
      // Inner arc in reverse
      path.arcTo(innerRect, startAngle + sweepAngle, -sweepAngle, false);
      path.close();
      return path;
    }

    // 1. Red: Top segment (-135° to -45°)
    final red = buildWedge(-3.0 * math.pi / 4.0, math.pi / 2.0);

    // 2. Yellow: Left segment (135° to 225° / -135°)
    final yellow = buildWedge(3.0 * math.pi / 4.0, math.pi / 2.0);

    // 3. Green: Bottom segment (45° to 135°)
    final green = buildWedge(math.pi / 4.0, math.pi / 2.0);

    // 4. Blue Arc: Bottom-right segment (0° to 45°)
    // Leaving -45° to 0° completely OPEN as the Google "G" mouth
    final blueArc = buildWedge(0.0, math.pi / 4.0);

    // 5. Blue Horizontal Bar: from center extending right through the G mouth
    final barHeight = (radius - innerRadius) * 0.95;
    final bar = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        center.dx - 1.0,
        center.dy - barHeight / 2.0,
        radius + 1.0,
        barHeight,
      ),
      const Radius.circular(1.0),
    );

    return _GoogleLogoPainter._(
      redPath: red,
      yellowPath: yellow,
      greenPath: green,
      blueArcPath: blueArc,
      barRect: bar,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Red segment
    _paint.color = const Color(0xFFEA4335);
    canvas.drawPath(redPath, _paint);

    // Yellow segment
    _paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(yellowPath, _paint);

    // Green segment
    _paint.color = const Color(0xFF34A853);
    canvas.drawPath(greenPath, _paint);

    // Blue segments (bottom-right arc + horizontal bar)
    _paint.color = const Color(0xFF4285F4);
    canvas.drawPath(blueArcPath, _paint);
    canvas.drawRRect(barRect, _paint);
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}

/// A standard divider with centered 'OR' text for authentication screens.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E3);
    final textColor = isDark ? const Color(0xFF78716C) : const Color(0xFFA8A29E);

    return Row(
      children: [
        Expanded(child: Divider(color: borderColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: AppTypography.caption.copyWith(color: textColor),
          ),
        ),
        Expanded(child: Divider(color: borderColor)),
      ],
    );
  }
}
