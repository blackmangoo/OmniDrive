import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/motion/motion_tappable.dart';

/// Official Apple Sign-In Button compliant with Apple Human Interface Guidelines (HIG).
class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const AppleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'Continue with Apple',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // On dark themes, Apple buttons use clean white on black or black on white with high contrast
    final bgColor = isDark ? Colors.white : Colors.black;
    final fgColor = isDark ? Colors.black : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TappableScale(
        onTap: isLoading ? null : onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.rLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.08),
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
                      color: fgColor,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppleLogo(size: 20, color: fgColor),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: AppTypography.label.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: fgColor,
                          letterSpacing: -0.2,
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

/// Vector Apple Logo
class AppleLogo extends StatelessWidget {
  final double size;
  final Color color;

  const AppleLogo({
    super.key,
    this.size = 20,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AppleLogoPainter(color: color),
      ),
    );
  }
}

class _AppleLogoPainter extends CustomPainter {
  final Color color;
  const _AppleLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Scale from normalized 100x100 coordinate space
    final sx = w / 100.0;
    final sy = h / 100.0;

    canvas.save();
    canvas.scale(sx, sy);

    // 1. Leaf
    final leaf = Path()
      ..moveTo(51.2, 23.5)
      ..cubicTo(56.3, 17.2, 59.8, 8.5, 58.8, 0.0)
      ..cubicTo(51.3, 0.3, 42.1, 5.1, 36.8, 11.3)
      ..cubicTo(32.1, 16.7, 28.0, 25.5, 29.2, 33.8)
      ..cubicTo(37.5, 34.4, 46.2, 29.5, 51.2, 23.5)
      ..close();
    canvas.drawPath(leaf, paint);

    // 2. Apple Body with right bite
    final body = Path()
      ..moveTo(74.6, 68.2)
      ..cubicTo(78.5, 62.5, 81.8, 56.1, 84.4, 49.3)
      ..cubicTo(73.5, 43.8, 66.8, 32.1, 67.2, 19.4)
      ..cubicTo(67.5, 17.7, 67.8, 16.0, 68.2, 14.3)
      ..cubicTo(60.9, 13.9, 53.6, 18.2, 49.3, 18.2)
      ..cubicTo(44.7, 18.2, 38.3, 14.2, 32.4, 14.3)
      ..cubicTo(20.3, 14.5, 9.4, 21.6, 3.8, 32.7)
      ..cubicTo(-4.5, 49.2, 1.7, 73.8, 9.7, 85.3)
      ..cubicTo(13.6, 91.0, 18.3, 97.2, 24.5, 97.0)
      ..cubicTo(30.4, 96.8, 32.7, 93.2, 39.8, 93.2)
      ..cubicTo(46.8, 93.2, 48.9, 97.0, 55.1, 96.9)
      ..cubicTo(61.5, 96.8, 65.7, 91.2, 69.6, 85.5)
      ..cubicTo(74.1, 78.9, 76.0, 75.5, 78.9, 69.7)
      ..cubicTo(77.3, 69.2, 75.8, 68.6, 74.6, 68.2)
      ..close();
    canvas.drawPath(body, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AppleLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
