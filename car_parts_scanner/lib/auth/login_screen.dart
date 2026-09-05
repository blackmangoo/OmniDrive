import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_screen.dart';
import 'vendor_signup_screen.dart';
import 'forgot_password_screen.dart';
import 'verify_email_screen.dart';
import '../marketplace/marketplace_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_shadows.dart';
import '../core/motion/motion_tappable.dart';

class LoginScreen extends StatefulWidget {
  final int preselectedRole;
  const LoginScreen({super.key, this.preselectedRole = 0});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading     = false;
  bool _obscurePass = true;
  DateTime? _lastLoginTap;
  // 0=Customer, 1=Vendor, 2=Rider
  int _roleIndex = 0;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _roleIndex = widget.preselectedRole;
    _fadeCtrl = AnimationController(
        vsync: this, duration: Duration(milliseconds: 600))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (_roleIndex) {
      case 1: return AppColors.vendorDark;
      case 2: return AppColors.riderDark;
      default: return AppColors.cyan;
    }
  }

  String get _roleLabel {
    switch (_roleIndex) {
      case 1: return 'Vendor';
      case 2: return 'Rider';
      default: return 'Customer';
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    if (_lastLoginTap != null && now.difference(_lastLoginTap!) < Duration(seconds: 2)) return;
    _lastLoginTap = now;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      final user = response.user;
      if (user != null) {
        final actualRole = await MarketplaceService.getUserRole();
        final selectedRole = _roleLabel.toLowerCase();

        if (actualRole != selectedRole && actualRole != 'admin') {
          await Supabase.instance.client.auth.signOut();
          if (!mounted) return;
          _showErrorDialog(
            'Wrong Role Selected',
            'This is a ${actualRole.toUpperCase()} account.\n\nPlease tap the "${actualRole[0].toUpperCase()}${actualRole.substring(1)}" tab at the top, then try again.',
          );
          return;
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      String title = 'Login Failed';
      String msg = e.message;
      if (msg.contains('email_not_confirmed') || msg.contains('Email not confirmed')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyEmailScreen(
              email: _emailCtrl.text.trim(),
              password: _passCtrl.text,
            ),
          ),
        );
        return;
      } else if (msg.contains('Invalid login credentials')) {
        title = 'Invalid Credentials';
        msg = 'The email or password you entered is incorrect. Please try again.';
      }
      _showErrorDialog(title, msg);
    } catch (_) {
      _showErrorDialog('Connection Error', 'Could not connect to the server. Please check your internet connection and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg)),
        title: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 10),
            Expanded(child: Text(title, style: AppTypography.title.copyWith(fontSize: 18))),
          ],
        ),
        content: Text(message, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: AppTypography.label.copyWith(color: _accentColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.xl),

                  // ── Logo ─────────────────────────────────────────────────
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                          fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1),
                      children: [
                        TextSpan(text: 'Omni', style: TextStyle(color: AppColors.textPrimary)),
                        TextSpan(text: 'Drive', style: TextStyle(color: _accentColor)),
                        TextSpan(
                            text: ' AI',
                            style: TextStyle(color: Colors.white38, fontSize: 20)),
                      ],
                    ),
                  ),
                  SizedBox(height: 6),
                  Text('Welcome back', style: AppTypography.body.copyWith(color: AppColors.textMuted)),

                  SizedBox(height: 36),

                  // ── Role Selector ─────────────────────────────────────────
                  Text('Sign in as', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.rLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _RoleTab(label: 'Customer', icon: Icons.person_rounded, index: 0, selectedIndex: _roleIndex, accent: AppColors.customer, onTap: () => setState(() => _roleIndex = 0)),
                        _RoleTab(label: 'Vendor',   icon: Icons.storefront_rounded, index: 1, selectedIndex: _roleIndex, accent: AppColors.vendorDark, onTap: () => setState(() => _roleIndex = 1)),
                        _RoleTab(label: 'Rider',    icon: Icons.delivery_dining_rounded, index: 2, selectedIndex: _roleIndex, accent: AppColors.rider, onTap: () => setState(() => _roleIndex = 2)),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // ── Email ────────────────────────────────────────────────
                  Text('Email', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
                  SizedBox(height: 8),
                  _AuthField(
                    controller: _emailCtrl,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    accentColor: _accentColor,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) return 'Enter a valid email';
                      return null;
                    },
                  ),

                  SizedBox(height: 20),

                  // ── Password ──────────────────────────────────────────────
                  Text('Password', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
                  SizedBox(height: 8),
                  _AuthField(
                    controller: _passCtrl,
                    hint: '••••••••',
                    obscureText: _obscurePass,
                    accentColor: _accentColor,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textMuted, size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'At least 6 characters';
                      return null;
                    },
                  ),

                  SizedBox(height: 12),
                  
                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: AppTypography.label.copyWith(
                          color: _accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 36),

                  // ── Login Button ───────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: TappableScale(
                      onTap: _loading ? null : _login,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(AppSpacing.rLg),
                          boxShadow: AppShadows.roleGlow(_accentColor),
                        ),
                        child: Center(
                          child: _loading
                              ? SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.black, strokeWidth: 2.5))
                              : Text('Log In as $_roleLabel',
                                  style: AppTypography.label.copyWith(
                                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 28),
                  _divider(),
                  SizedBox(height: 28),

                  // ── Sign up link ───────────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_roleIndex == 1) {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => VendorSignupScreen()));
                        } else if (_roleIndex == 2) {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => SignupScreen(role: 'rider')));
                        } else {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => SignupScreen()));
                        }
                      },
                      child: RichText(
                        text: TextSpan(
                          style: AppTypography.body,
                          children: [
                            TextSpan(text: "Don't have an account? ", style: TextStyle(color: AppColors.textMuted)),
                            TextSpan(text: 'Sign Up', style: TextStyle(color: _accentColor, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() => Row(children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ]);
}

// ── Role Tab ──────────────────────────────────────────────────────────────────
class _RoleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final int index;
  final int selectedIndex;
  final Color accent;
  final VoidCallback onTap;

  const _RoleTab({
    required this.label,
    required this.icon,
    required this.index,
    required this.selectedIndex,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = index == selectedIndex;
    return Expanded(
      child: TappableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 250),
          margin: EdgeInsets.all(AppSpacing.xxs),
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.rLg),
            border: Border.all(
              color: selected ? accent.withValues(alpha: 0.3) : Colors.transparent,
              width: 1,
            ),
            boxShadow: selected ? AppShadows.roleGlow(accent) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? accent : AppColors.textMuted, size: 22),
              SizedBox(height: 6),
              Text(label,
                  style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? accent : AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable Auth Field ───────────────────────────────────────────────────────
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final Color accentColor;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.accentColor,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
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
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg), borderSide: BorderSide(color: accentColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg), borderSide: BorderSide(color: AppColors.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.rLg), borderSide: BorderSide(color: AppColors.error)),
      ),
    );
  }
}
