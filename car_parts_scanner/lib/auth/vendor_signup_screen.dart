import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_gate.dart';
import 'verify_email_screen.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_shadows.dart';
import '../core/motion/motion_tappable.dart';

class VendorSignupScreen extends StatefulWidget {
  const VendorSignupScreen({super.key});
  @override
  State<VendorSignupScreen> createState() => _VendorSignupScreenState();
}

class _VendorSignupScreenState extends State<VendorSignupScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _shopCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _locCtrl    = TextEditingController();
  bool _loading     = false;
  bool _obscure     = true;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _passCtrl, _shopCtrl, _phoneCtrl, _locCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Color get _accentColor => AppColors.vendorDark;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // Prevent AuthGate from reacting to the automatic signedIn event
      AuthGate.suppressNextSignIn();

      await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        data: {
          'full_name': _nameCtrl.text.trim(),
          'role': 'vendor',
          'shop_name': _shopCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'location': _locCtrl.text.trim(),
        },
        emailRedirectTo: 'omnidrive://login-callback/',
      );

      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: _emailCtrl.text.trim())));
    } on AuthException catch (e) {
      _showError(e.message.contains('already') ? 'This email is already registered.' : e.message);
    } catch (e) {
      _showError('Connection error. Try again.');
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.rLg),
                        boxShadow: AppShadows.roleGlow(_accentColor),
                      ),
                      child: Icon(Icons.storefront_rounded, color: _accentColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vendor Account', style: AppTypography.h2),
                        Text('Set up your shop on OmniDrive', style: AppTypography.caption),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Section: Personal Info ─────────────────────────────────
                _sectionHeader('Personal Information'),
                const SizedBox(height: 12),
                _Field(ctrl: _nameCtrl, label: 'Full Name', hint: 'John Smith', accentColor: _accentColor,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
                const SizedBox(height: 14),
                _Field(ctrl: _emailCtrl, label: 'Email', hint: 'vendor@example.com', keyboardType: TextInputType.emailAddress, accentColor: _accentColor,
                    validator: (v) => (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v ?? '')) ? 'Enter a valid email' : null),
                const SizedBox(height: 14),
                _Field(ctrl: _phoneCtrl, label: 'Phone Number', hint: '+92 300 0000000', keyboardType: TextInputType.phone, accentColor: _accentColor,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
                const SizedBox(height: 14),
                _Field(
                  ctrl: _passCtrl, label: 'Password', hint: 'Min. 8 characters', obscureText: _obscure, accentColor: _accentColor,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => (v?.length ?? 0) < 8 ? 'Min. 8 characters' : null,
                ),

                const SizedBox(height: 28),

                // ── Section: Shop Info ─────────────────────────────────────
                _sectionHeader('Shop Information'),
                const SizedBox(height: 12),
                _Field(ctrl: _shopCtrl, label: 'Shop Name', hint: 'Ali Auto Parts', accentColor: _accentColor,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
                const SizedBox(height: 14),
                _Field(ctrl: _locCtrl, label: 'Shop Location / Area', hint: 'Model Town, Lahore', accentColor: _accentColor,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),

                const SizedBox(height: 36),

                // ── Submit ──────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: TappableScale(
                    onTap: _loading ? null : _signup,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: BorderRadius.circular(AppSpacing.rLg),
                        boxShadow: AppShadows.roleGlow(_accentColor),
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                            : Text('Create Vendor Account', style: AppTypography.label.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('Already have an account? Log In',
                        style: AppTypography.body.copyWith(color: _accentColor, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Row(
    children: [
      Container(width: 3, height: 18, decoration: BoxDecoration(color: _accentColor, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title, style: AppTypography.label.copyWith(color: AppColors.textPrimary, letterSpacing: 0.5)),
    ],
  );
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final Color accentColor;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.accentColor,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: AppTypography.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg), borderSide: BorderSide(color: accentColor, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg), borderSide: const BorderSide(color: AppColors.error)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg), borderSide: const BorderSide(color: AppColors.error)),
        ),
      ),
    ]);
  }
}
