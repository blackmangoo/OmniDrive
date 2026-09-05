import 'package:flutter/material.dart';

class PremiumPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  PremiumPageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Respect reduced-motion settings
            if (MediaQuery.of(context).disableAnimations) {
              return child;
            }

            beginScale = 0.96;
            endScale = 1.0;
            final scaleCurve = CurveTween(curve: Curves.easeOutCubic);
            final scaleAnimation = animation.drive(Tween(begin: beginScale, end: endScale).chain(scaleCurve));

            final fadeCurve = CurveTween(curve: Curves.easeInOutCubic);
            final fadeAnimation = animation.drive(Tween(begin: 0.0, end: 1.0).chain(fadeCurve));

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: Duration(milliseconds: 300),
          reverseTransitionDuration: Duration(milliseconds: 250),
        );
}
