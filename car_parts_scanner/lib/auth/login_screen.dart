import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_screen.dart';
import 'vendor_signup_screen.dart';
import 'forgot_password_screen.dart';
import 'verify_email_screen.dart';
import '../marketplace/marketplace_service.dart';


const _kBg      = Color(0xFF0A0A0F);
const _kSurface = Color(0xFF12121A);
const _kAccent  = Color(0xFF4FC3F7);
const _kVendor  = Color(0xFFF59E0B);
const _kBorder  = Color(0xFF1E1E2E);

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
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
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
      case 1: return _kVendor;
      case 2: return const Color(0xFF8B5CF6);
      default: return _kAccent;
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
    // Debounce: prevent double-tap within 2 seconds
    final now = DateTime.now();
    if (_lastLoginTap != null && now.difference(_lastLoginTap!) < const Duration(seconds: 2)) return;
    _lastLoginTap = now;
    // Dismiss keyboard before login to ensure dialogs are fully visible
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
      // If roles match, AuthGate handles the navigation automatically
    } on AuthException catch (e) {
      if (!mounted) return;
      String title = 'Login Failed';
      String msg = e.message;
      if (msg.contains('email_not_confirmed') || msg.contains('Email not confirmed')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyEmailScreen(email: _emailCtrl.text.trim()),
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
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
          ],
        ),
        content: Text(message, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: GoogleFonts.inter(color: _accentColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // ── Logo ─────────────────────────────────────────────────
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                          fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1),
                      children: [
                        const TextSpan(text: 'Omni', style: TextStyle(color: Colors.white)),
                        TextSpan(text: 'Drive', style: TextStyle(color: _accentColor)),
                        const TextSpan(
                            text: ' AI',
                            style: TextStyle(color: Colors.white38, fontSize: 20)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Welcome back', style: GoogleFonts.inter(color: Colors.white38, fontSize: 15)),

                  const SizedBox(height: 36),

                  // ── Role Selector ─────────────────────────────────────────
                  Text('Sign in as', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Row(
                      children: [
                        _RoleTab(label: 'Customer', icon: Icons.person_rounded, index: 0, selectedIndex: _roleIndex, accent: _kAccent, onTap: () => setState(() => _roleIndex = 0)),
                        _RoleTab(label: 'Vendor',   icon: Icons.storefront_rounded, index: 1, selectedIndex: _roleIndex, accent: _kVendor, onTap: () => setState(() => _roleIndex = 1)),
                        _RoleTab(label: 'Rider',    icon: Icons.delivery_dining_rounded, index: 2, selectedIndex: _roleIndex, accent: const Color(0xFF8B5CF6), onTap: () => setState(() => _roleIndex = 2)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Email ────────────────────────────────────────────────
                  Text('Email', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
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

                  const SizedBox(height: 20),

                  // ── Password ──────────────────────────────────────────────
                  Text('Password', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _AuthField(
                    controller: _passCtrl,
                    hint: '••••••••',
                    obscureText: _obscurePass,
                    accentColor: _accentColor,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white38, size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'At least 6 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),
                  
                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.inter(
                          color: _accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Login Button ───────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2.5))
                          : Text('Log In as $_roleLabel',
                              style: GoogleFonts.inter(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 28),
                  _divider(),
                  const SizedBox(height: 28),

                  // ── Sign up link ───────────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        if (_roleIndex == 1) {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const VendorSignupScreen()));
                        } else if (_roleIndex == 2) {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SignupScreen(role: 'rider')));
                        } else {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SignupScreen()));
                        }
                      },
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(fontSize: 14),
                          children: [
                            const TextSpan(text: "Don't have an account? ", style: TextStyle(color: Colors.white38)),
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
        Expanded(child: Divider(color: Colors.white12)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR', style: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
        ),
        Expanded(child: Divider(color: Colors.white12)),
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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: selected ? Border.all(color: accent.withValues(alpha: 0.4)) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? accent : Colors.white38, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? accent : Colors.white38)),
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
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white24),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF12121A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E1E2E))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E1E2E))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accentColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }
}
