import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'update_password_screen.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_shadows.dart';
import '../core/motion/motion_tappable.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _emailSent = false;

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address');
      return;
    }

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'omnidrive://login-callback/',
      );
      setState(() => _emailSent = true);
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Connection error. Check your internet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailCtrl.text.trim();
    final input = _codeCtrl.text.trim();
    if (input.isEmpty) {
      _showError('Please enter the code or paste the link');
      return;
    }

    setState(() => _loading = true);
    try {
      String token = input;
      String? accessToken;
      String? refreshToken;

      if (input.startsWith('http') || input.contains('://') || input.contains('#') || input.contains('?')) {
        try {
          final uri = Uri.parse(input);
          if (uri.queryParameters.containsKey('token')) {
            token = uri.queryParameters['token']!;
          } else if (uri.queryParameters.containsKey('token_hash')) {
            token = uri.queryParameters['token_hash']!;
          }

          if (uri.fragment.isNotEmpty) {
            final fragmentParams = Uri.splitQueryString(uri.fragment);
            if (fragmentParams.containsKey('access_token')) {
              accessToken = fragmentParams['access_token'];
              refreshToken = fragmentParams['refresh_token'];
            }
          }
        } catch (_) {}
      }

      if (accessToken != null && refreshToken != null) {
        await Supabase.instance.client.auth.setSession(refreshToken);
      } else {
        await Supabase.instance.client.auth.verifyOTP(
          email: email,
          token: token,
          type: OtpType.recovery,
        );
      }

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()),
      ).then((_) {
        if (mounted) {
          setState(() {
            _emailSent = false;
            _codeCtrl.clear();
            _emailCtrl.clear();
          });
        }
      });
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Verification failed. Check your code or link.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppTypography.body.copyWith(color: Colors.white)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reset Password', style: AppTypography.display.copyWith(fontSize: 32)),
              const SizedBox(height: 12),
              Text(
                _emailSent 
                  ? 'Check your email for a password reset link or recovery code. Click the link on this device, OR copy and paste the code/link below to reset:'
                  : 'Enter your email address and we will send you a link to reset your password.', 
                style: AppTypography.body.copyWith(color: AppColors.textSecondary)
              ),
              const SizedBox(height: 40),
              
              if (!_emailSent) ...[
                Text('Email', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'you@example.com',
                    hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg), borderSide: const BorderSide(color: AppColors.cyan, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 36),
                
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: TappableScale(
                    onTap: _loading ? null : _resetPassword,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cyan,
                        borderRadius: BorderRadius.circular(AppSpacing.rLg),
                        boxShadow: AppShadows.cyanGlow,
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                            : Text('Send Reset Link', style: AppTypography.label.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Text('Recovery Code or Link', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _codeCtrl,
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter 6-digit code or paste recovery link',
                    hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg), borderSide: const BorderSide(color: AppColors.cyan, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 36),
                
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: TappableScale(
                    onTap: _loading ? null : _verifyCode,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cyan,
                        borderRadius: BorderRadius.circular(AppSpacing.rLg),
                        boxShadow: AppShadows.cyanGlow,
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                            : Text('Verify & Reset Password', style: AppTypography.label.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _emailSent = false),
                    child: Text('Resend email / Change email', style: AppTypography.label.copyWith(color: AppColors.cyan)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
