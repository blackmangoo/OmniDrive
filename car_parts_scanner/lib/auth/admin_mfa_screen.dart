import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_gate.dart';
import '../marketplace/marketplace_constants.dart';

class AdminMfaScreen extends StatefulWidget {
  const AdminMfaScreen({super.key});

  @override
  State<AdminMfaScreen> createState() => _AdminMfaScreenState();
}

enum MfaState {
  checkingStatus,
  enrolling,
  challenging,
  success,
  error,
}

class _AdminMfaScreenState extends State<AdminMfaScreen> {
  MfaState _state = MfaState.checkingStatus;
  String? _errorMessage;
  bool _submitting = false;
  String? _qrCodeData;
  String? _secretKey;
  String? _factorId;
  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initMfa();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _initMfa() async {
    if (!mounted) return;
    setState(() {
      _state = MfaState.checkingStatus;
      _errorMessage = null;
    });

    try {
      final factors = await Supabase.instance.client.auth.mfa.listFactors();
      final verifiedTotp = factors.totp.where((f) => f.status == FactorStatus.verified).toList();

      if (verifiedTotp.isNotEmpty) {
        // Enrolled and verified previously -> Challenge Mode
        _factorId = verifiedTotp.first.id;
        setState(() {
          _state = MfaState.challenging;
        });
      } else {
        // Not enrolled or not verified previously -> Enrollment Mode
        final response = await Supabase.instance.client.auth.mfa.enroll(
          factorType: FactorType.totp,
          issuer: 'OmniDrive AI',
          friendlyName: 'Admin Authenticator',
        );

        _factorId = response.id;
        _qrCodeData = response.totp?.qrCode;
        _secretKey = response.totp?.secret;

        setState(() {
          _state = MfaState.enrolling;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _state = MfaState.error;
        });
        _showSnackBar('MFA Setup check failed: $e', isError: true);
      }
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      _showSnackBar('Please enter a 6-digit code', isError: true);
      return;
    }

    setState(() => _submitting = true);

    try {
      // Create a challenge and verify it
      final challenge = await Supabase.instance.client.auth.mfa.challenge(factorId: _factorId!);
      await Supabase.instance.client.auth.mfa.verify(
        factorId: _factorId!,
        challengeId: challenge.id,
        code: code,
      );

      if (mounted) {
        setState(() {
          _state = MfaState.success;
          _submitting = false;
        });
      }

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _showSnackBar('Verification failed: Invalid code or network error.', isError: true);
      }
    }
  }

  Future<void> _signOut() async {
    setState(() => _submitting = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _showSnackBar('Sign out failed: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? kError : kSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _signOut();
      },
      child: Scaffold(
        backgroundColor: kBg,
        body: Container(
          decoration: const BoxDecoration(gradient: kBgGradient),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _buildStateContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent() {
    switch (_state) {
      case MfaState.checkingStatus:
        return _buildLoading('Checking MFA status...');
      case MfaState.enrolling:
        return _buildEnrollmentView();
      case MfaState.challenging:
        return _buildChallengeView();
      case MfaState.success:
        return const _SuccessCheckAnimation();
      case MfaState.error:
        return _buildErrorView();
    }
  }

  Widget _buildLoading(String message) {
    return Column(
      key: const ValueKey('loading'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(color: kAdmin, strokeWidth: 3.5),
        ),
        const SizedBox(height: 24),
        Text(
          message,
          style: kBody(15, color: kTextSecondary),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      key: const ValueKey('error'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded, color: kError, size: 64),
        const SizedBox(height: 24),
        Text(
          'Authentication Error',
          style: kHeadline(22, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage ?? 'Something went wrong',
          textAlign: TextAlign.center,
          style: kBody(14, color: kTextSecondary),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _initMfa,
          style: ElevatedButton.styleFrom(
            backgroundColor: kAdmin,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.refresh_rounded),
          label: Text('Retry Setup', style: kHeadline(14, color: Colors.white)),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _submitting ? null : _signOut,
          child: Text(
            'Back to Login',
            style: kBody(14, color: kTextSecondary, fw: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentView() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('enrollment'),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kAdmin.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: kAdmin.withValues(alpha: 0.3), width: 1.5),
            ),
            child: const Icon(Icons.security_rounded, color: kAdmin, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'Setup Authenticator MFA',
            style: kHeadline(24, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Scan this QR code with Google Authenticator or copy the Secret Key to set up.',
              textAlign: TextAlign.center,
              style: kBody(14, color: kTextSecondary),
            ),
          ),
          const SizedBox(height: 28),
          if (_qrCodeData != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(_qrCodeData!)}',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 200,
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image_rounded, color: kError, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load QR code',
                          style: kBody(12, color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: kAdmin,
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          if (_secretKey != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secret Key',
                          style: kLabel(11, color: kTextMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _secretKey!,
                          style: GoogleFonts.robotoMono(
                            color: kTextSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _secretKey!));
                      _showSnackBar('Secret key copied to clipboard!', isError: false);
                    },
                    icon: const Icon(Icons.copy_rounded, color: kAdmin),
                    tooltip: 'Copy Secret Key',
                  ),
                ],
              ),
            ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Enter 6-digit code',
              style: kLabel(13, color: kTextSecondary),
            ),
          ),
          const SizedBox(height: 8),
          _buildCodeInputField(),
          const SizedBox(height: 28),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildChallengeView() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('challenge'),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kAdmin.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: kAdmin.withValues(alpha: 0.3), width: 1.5),
            ),
            child: const Icon(Icons.lock_person_rounded, color: kAdmin, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'Admin MFA Verification',
            style: kHeadline(24, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Enter the 6-digit verification code from your Google Authenticator app to log in.',
              textAlign: TextAlign.center,
              style: kBody(14, color: kTextSecondary),
            ),
          ),
          const SizedBox(height: 36),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Enter 6-digit code',
              style: kLabel(13, color: kTextSecondary),
            ),
          ),
          const SizedBox(height: 8),
          _buildCodeInputField(),
          const SizedBox(height: 36),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCodeInputField() {
    return TextFormField(
      controller: _codeCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      textAlign: TextAlign.center,
      style: GoogleFonts.robotoMono(
        fontSize: 24,
        letterSpacing: 8,
        fontWeight: FontWeight.bold,
        color: kTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: '000000',
        hintStyle: GoogleFonts.robotoMono(
          fontSize: 24,
          letterSpacing: 8,
          color: kTextMuted.withValues(alpha: 0.3),
        ),
        filled: true,
        fillColor: kSurface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kAdmin, width: 1.5),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Code is required';
        if (v.length != 6) return 'Must be exactly 6 digits';
        return null;
      },
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: kAdmin,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    'Verify Code',
                    style: kHeadline(16, color: Colors.white, fw: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _submitting ? null : _signOut,
          child: Text(
            'Back to Login',
            style: kBody(14, color: kTextSecondary, fw: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _SuccessCheckAnimation extends StatefulWidget {
  const _SuccessCheckAnimation();

  @override
  State<_SuccessCheckAnimation> createState() => _SuccessCheckAnimationState();
}

class _SuccessCheckAnimationState extends State<_SuccessCheckAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.elasticOut,
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('success'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: kSuccess,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kSuccess,
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'MFA Verified',
          style: kHeadline(22, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Redirecting to Admin dashboard...',
          style: kBody(14, color: kTextSecondary),
        ),
      ],
    );
  }
}
