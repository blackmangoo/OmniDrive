import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'auth_gate.dart';

const _kBg     = Color(0xFF0A0A0F);
const _kAccent = Color(0xFF4FC3F7);

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  bool _resending = false;
  bool _verified  = false;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // KEY FIX: listen for the signedIn event that fires when the user clicks the
    // deep-link in the email. When it fires, pop ALL screens and go straight to
    // the AuthGate, which will then route to MainShell automatically.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        if (!mounted) return;
        setState(() => _verified = true);
        _pulseCtrl.stop();

        // Small delay so the user can briefly see the "Verified!" state
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          // Pop everything and go to root (AuthGate) which routes to MainShell
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
    _pulseCtrl.dispose();
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
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to resend: $e'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
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
        // Pulsing envelope icon
        ScaleTransition(
          scale: _pulse,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kAccent.withValues(alpha: 0.1),
              border: Border.all(color: _kAccent.withValues(alpha: 0.3), width: 1.5),
            ),
            child: const Icon(Icons.mark_email_unread_outlined,
                color: _kAccent, size: 54),
          ),
        ),

        const SizedBox(height: 36),

        const Text('Check Your Inbox',
            style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold)),

        const SizedBox(height: 14),

        Text(
          'We sent a link to\n${widget.email}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 15, height: 1.5),
        ),

        const SizedBox(height: 10),

        const Text(
          'Click the link in that email.\nThis screen will automatically update.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white30, fontSize: 13, height: 1.5),
        ),

        const SizedBox(height: 36),

        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white54, size: 18),
          label: const Text('Back to Login', style: TextStyle(color: Colors.white54)),
        ),

        const SizedBox(height: 48),

        // Already verified? Go to login manually
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AuthGate()),
              (_) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text("I've verified — Log In",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: 20),

        TextButton(
          onPressed: _resending ? null : _resend,
          child: _resending
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: _kAccent, strokeWidth: 2))
              : const Text("Didn't receive it? Resend",
                  style: TextStyle(color: Colors.white38, fontSize: 14)),
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
            color: Colors.green.withValues(alpha: 0.12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.5), width: 1.5),
          ),
          child: const Icon(Icons.check_circle_outline_rounded,
              color: Colors.green, size: 60),
        ),
        const SizedBox(height: 28),
        const Text('Email Verified!',
          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Taking you in...',
          style: TextStyle(color: Colors.white38, fontSize: 14)),
        const SizedBox(height: 24),
        const SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: _kAccent),
        ),
      ],
    );
  }
}
