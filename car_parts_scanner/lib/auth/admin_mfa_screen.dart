import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_gate.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/motion/motion_tappable.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

      await Future.delayed(Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => AuthGate()),
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
          MaterialPageRoute(builder: (_) => AuthGate()),
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
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 3),
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
        backgroundColor: AppColors.background,
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.3),
              radius: 1.2,
              colors: [
                AppColors.admin.withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 400),
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
        return _SuccessCheckAnimation();
      case MfaState.error:
        return _buildErrorView();
    }
  }

  Widget _buildLoading(String message) {
    return Column(
      key: ValueKey('loading'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(color: AppColors.admin, strokeWidth: 3.5),
        ),
        SizedBox(height: 24),
        Text(
          message,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      key: ValueKey('error'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline_rounded, color: AppColors.error, size: 64),
        SizedBox(height: 24),
        Text(
          'Authentication Error',
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
        SizedBox(height: 12),
        Text(
          _errorMessage ?? 'Something went wrong',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: 32),
        TappableScale(
          onTap: _initMfa,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.admin,
              borderRadius: BorderRadius.circular(AppSpacing.rMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.admin.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Retry Setup',
                  style: AppTypography.title.copyWith(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        TappableScale(
          onTap: _submitting ? null : _signOut,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Back to Login',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentView() {
    return Form(
      key: _formKey,
      child: Column(
        key: ValueKey('enrollment'),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.admin.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.admin.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(Icons.security_rounded, color: AppColors.admin, size: 40),
          ),
          SizedBox(height: 20),
          Text(
            'Setup Authenticator MFA',
            style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Scan this QR code with Google Authenticator or copy the Secret Key to set up.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          SizedBox(height: 28),
          if (_qrCodeData != null)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
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
                        Icon(Icons.broken_image_rounded, color: AppColors.error, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'Failed to load QR code',
                          style: AppTypography.body.copyWith(color: Colors.black54, fontSize: 12),
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
                        color: AppColors.admin,
                      ),
                    ),
                  );
                },
              ),
            ),
          SizedBox(height: 20),
          if (_secretKey != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.rMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secret Key',
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _secretKey!,
                          style: GoogleFonts.robotoMono(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _secretKey!));
                      _showSnackBar('Secret key copied to clipboard!', isError: false);
                    },
                    icon: Icon(Icons.copy_rounded, color: AppColors.admin),
                    tooltip: 'Copy Secret Key',
                  ),
                ],
              ),
            ),
          SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Enter 6-digit code',
              style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          SizedBox(height: 8),
          _buildCodeInputField(),
          SizedBox(height: 28),
          _buildActionButtons(),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),
    );
  }

  Widget _buildChallengeView() {
    return Form(
      key: _formKey,
      child: Column(
        key: ValueKey('challenge'),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.admin.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.admin.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(Icons.lock_person_rounded, color: AppColors.admin, size: 40),
          ),
          SizedBox(height: 20),
          Text(
            'Admin MFA Verification',
            style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Enter the 6-digit verification code from your Google Authenticator app to log in.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          SizedBox(height: 36),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Enter 6-digit code',
              style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          SizedBox(height: 8),
          _buildCodeInputField(),
          SizedBox(height: 36),
          _buildActionButtons(),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),
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
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: '000000',
        hintStyle: GoogleFonts.robotoMono(
          fontSize: 24,
          letterSpacing: 8,
          color: AppColors.textMuted.withValues(alpha: 0.3),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.rMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.rMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.rMd),
          borderSide: BorderSide(color: AppColors.admin, width: 1.5),
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
          child: TappableScale(
            onTap: _submitting ? null : _verifyCode,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.admin,
                borderRadius: BorderRadius.circular(AppSpacing.rMd),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.admin.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: _submitting
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'Verify Code',
                      style: AppTypography.title.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
        SizedBox(height: 16),
        TappableScale(
          onTap: _submitting ? null : _signOut,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              'Back to Login',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textSecondary,
              ),
            ),
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
      duration: Duration(milliseconds: 600),
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
    if (MediaQuery.of(context).disableAnimations) {
      return Column(
        key: ValueKey('success'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 64,
            ),
          ),
          SizedBox(height: 28),
          Text(
            'MFA Verified',
            style: AppTypography.h2.copyWith(color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            'Redirecting to Admin dashboard...',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return Column(
      key: ValueKey('success'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success,
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
        SizedBox(height: 28),
        Text(
          'MFA Verified',
          style: AppTypography.h2.copyWith(color: Colors.white),
        ),
        SizedBox(height: 8),
        Text(
          'Redirecting to Admin dashboard...',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
