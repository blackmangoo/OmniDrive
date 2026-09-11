import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TappableScale(
        onTap: isLoading ? null : onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.rLg),
            border: Border.all(
              color: isDark ? AppColors.border : const Color(0xFFE5E5E3),
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
                      color: AppColors.textPrimary,
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
                          color: AppColors.textPrimary,
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

/// Official 4-color Google "G" Emblem rendered via high-precision vectors.
class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final innerRadius = radius * 0.58;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Red (Top segment)
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -2.356, // -135 deg
        1.571,  // 90 deg
        false,
      )
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.save();
    canvas.clipPath(_donutMask(center, radius, innerRadius));
    canvas.drawPath(redPath, paint);
    canvas.restore();

    // Yellow (Left segment)
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        2.356, // 135 deg
        1.571, // 90 deg
        false,
      )
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.save();
    canvas.clipPath(_donutMask(center, radius, innerRadius));
    canvas.drawPath(yellowPath, paint);
    canvas.restore();

    // Green (Bottom segment)
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        0.785, // 45 deg
        1.571, // 90 deg
        false,
      )
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.save();
    canvas.clipPath(_donutMask(center, radius, innerRadius));
    canvas.drawPath(greenPath, paint);
    canvas.restore();

    // Blue (Right arc + horizontal bar)
    paint.color = const Color(0xFF4285F4);
    final blueArc = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -0.785, // -45 deg
        1.571,  // 90 deg
        false,
      )
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.save();
    canvas.clipPath(_donutMask(center, radius, innerRadius));
    canvas.drawPath(blueArc, paint);
    canvas.restore();

    // Blue horizontal bar
    final barHeight = (radius - innerRadius) * 0.95;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        center.dx - 1,
        center.dy - barHeight / 2,
        radius + 1,
        barHeight,
      ),
      const Radius.circular(1),
    );
    canvas.drawRRect(barRect, paint);
  }

  Path _donutMask(Offset center, double outer, double inner) {
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: outer))
      ..addOval(Rect.fromCircle(center: center, radius: inner))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
