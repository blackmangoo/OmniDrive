import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';
import 'auth_gate.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_shadows.dart';
import '../core/motion/motion_tappable.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String? password;
  const VerifyEmailScreen({super.key, required this.email, this.password});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _resending = false;
  bool _verified  = false;
  bool _checkingStatus = false;

  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (data.event == AuthChangeEvent.signedIn &&
          session != null &&
          session.user.emailConfirmedAt != null) {
        if (!mounted) return;
        setState(() => _verified = true);

        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthGate()),
            (_) => false,
          );
        });
      }
    });

  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Verification email resent. Check your inbox.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to resend: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }



  Future<void> _checkVerificationStatus() async {
    setState(() => _checkingStatus = true);
    try {
      if (widget.password != null && widget.password!.isNotEmpty) {
        // If the user clicked the link on ANOTHER device, this app instance has no session
        // and deep links won't reach here. The best way to check is to attempt a login.
        await Supabase.instance.client.auth.signInWithPassword(
          email: widget.email,
          password: widget.password!,
        );
      } else {
        // Fallback if password is not available
        final response = await Supabase.instance.client.auth.getUser();
        final user = response.user;
        if (user == null || user.emailConfirmedAt == null) {
          throw const AuthException('Email not confirmed');
        }
      }

      if (!mounted) return;
      setState(() => _verified = true);

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
        );
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.message.contains('Email not confirmed')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Email has not been verified yet. Please check your inbox."),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Verification check failed: ${e.message}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Verification check failed: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) {
        setState(() => _checkingStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _verified ? _buildVerified() : _buildWaiting(),
          ),
        ),
      ),
    );
  }

  Widget _buildWaiting() {
    return Column(
      key: const ValueKey('waiting'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cyan.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3), width: 1.5),
            boxShadow: AppShadows.cyanGlow,
          ),
          child: const Icon(Icons.mark_email_unread_outlined,
              color: AppColors.cyan, size: 54),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(0.92, 0.92), end: const Offset(1.08, 1.08), duration: 1500.ms, curve: Curves.easeInOutCubic),

        const SizedBox(height: 36),

        Text('Check Your Inbox',
            style: AppTypography.display.copyWith(fontSize: 26)),

        const SizedBox(height: 14),

        Text(
          'We sent a link to\n${widget.email}',
          textAlign: TextAlign.center,
          style: AppTypography.body,
        ),

        const SizedBox(height: 10),

        Text(
          'Click the link in that email.\nIf you click it on another device, click the button below after verifying.',
          textAlign: TextAlign.center,
          style: AppTypography.caption,
        ),

        const SizedBox(height: 36),

        TextButton.icon(
          onPressed: () async {
            try {
              await Supabase.instance.client.auth.signOut();
            } catch (e) {
              debugPrint('Sign out error: $e');
            }
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          },
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary, size: 18),
          label: Text('Back to Login', style: AppTypography.label),
        ),

        const SizedBox(height: 48),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: TappableScale(
            onTap: _checkingStatus ? null : _checkVerificationStatus,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cyan,
                borderRadius: BorderRadius.circular(AppSpacing.rLg),
                boxShadow: AppShadows.cyanGlow,
              ),
              child: Center(
                child: _checkingStatus
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text("I've verified — Log In",
                        style: AppTypography.label.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        TextButton(
          onPressed: _resending ? null : _resend,
          child: _resending
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: AppColors.cyan, strokeWidth: 2))
              : Text("Didn't receive it? Resend",
                  style: AppTypography.label.copyWith(color: AppColors.textMuted)),
        ),
      ],
    );
  }

  Widget _buildVerified() {
    return Column(
      key: const ValueKey('verified'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.5), width: 1.5),
            boxShadow: AppShadows.roleGlow(AppColors.success),
          ),
          child: const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.success, size: 60),
        ),
        const SizedBox(height: 28),
        Text('Email Verified!',
          style: AppTypography.display.copyWith(fontSize: 26)),
        const SizedBox(height: 10),
        Text('Taking you in...',
          style: AppTypography.body.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 24),
        const SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.cyan),
        ),
      ],
    );
  }
}
