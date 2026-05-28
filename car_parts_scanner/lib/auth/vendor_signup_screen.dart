import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../marketplace/marketplace_service.dart';
import 'verify_email_screen.dart';

const _kBg      = Color(0xFF0A0A0F);
const _kSurface = Color(0xFF12121A);
const _kAccent  = Color(0xFFF59E0B); // amber for vendor
const _kBorder  = Color(0xFF1E1E2E);

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

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client.auth.signUp(
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
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: _kAccent, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vendor Account', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('Set up your shop on OmniDrive', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Section: Personal Info ─────────────────────────────────
                _sectionHeader('Personal Information'),
                const SizedBox(height: 12),
                _Field(ctrl: _nameCtrl, label: 'Full Name', hint: 'John Smith', accentColor: _kAccent,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
                const SizedBox(height: 14),
                _Field(ctrl: _emailCtrl, label: 'Email', hint: 'vendor@example.com', keyboardType: TextInputType.emailAddress, accentColor: _kAccent,
                    validator: (v) => (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v ?? '')) ? 'Enter a valid email' : null),
                const SizedBox(height: 14),
                _Field(ctrl: _phoneCtrl, label: 'Phone Number', hint: '+92 300 0000000', keyboardType: TextInputType.phone, accentColor: _kAccent,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
                const SizedBox(height: 14),
                _Field(
                  ctrl: _passCtrl, label: 'Password', hint: 'Min. 8 characters', obscureText: _obscure, accentColor: _kAccent,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white38, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => (v?.length ?? 0) < 8 ? 'Min. 8 characters' : null,
                ),

                const SizedBox(height: 28),

                // ── Section: Shop Info ─────────────────────────────────────
                _sectionHeader('Shop Information'),
                const SizedBox(height: 12),
                _Field(ctrl: _shopCtrl, label: 'Shop Name', hint: 'Ali Auto Parts', accentColor: _kAccent,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
                const SizedBox(height: 14),
                _Field(ctrl: _locCtrl, label: 'Shop Location / Area', hint: 'Model Town, Lahore', accentColor: _kAccent,
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),

                const SizedBox(height: 36),

                // ── Submit ──────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                        : Text('Create Vendor Account', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('Already have an account? Log In',
                        style: GoogleFonts.inter(color: _kAccent, fontSize: 14, fontWeight: FontWeight.w600)),
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
      Container(width: 3, height: 18, decoration: BoxDecoration(color: _kAccent, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
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
      Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white24),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: _kSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accentColor, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
        ),
      ),
    ]);
  }
}
