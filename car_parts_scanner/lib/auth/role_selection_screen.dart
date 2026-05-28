import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../marketplace/marketplace_constants.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Role Selection / Login  (Stitch Design: Login / Role Selection)
// ─────────────────────────────────────────────────────────────────────────────
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  String _selected = 'customer';
  late AnimationController _ctrl;
  late Animation<double> _fade;

  static const _roles = [
    _RoleData('customer', 'Customer', 'Shop local auto parts & book mobility services.',
        Icons.shopping_bag_rounded, kCyan),
    _RoleData('vendor', 'Vendor', 'Expand your business reach across the urban ecosystem.',
        Icons.storefront_rounded, kVendor),
    _RoleData('rider', 'Rider', 'Join the fleet — deliver fast, earn on your schedule.',
        Icons.delivery_dining_rounded, kRider),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final accent = _roles.firstWhere((r) => r.id == _selected).accent;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kBgGradient),
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            child: Column(
              children: [
                // ── Top gradient blob ──────────────────────────────────────
                SizedBox(
                  height: 220,
                  child: Stack(
                    children: [
                      Positioned(
                        top: -40, left: -40,
                        child: Container(
                          width: 260, height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              accent.withValues(alpha: 0.25), Colors.transparent,
                            ]),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 24),
                            // Logo
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [accent, accent.withValues(alpha: 0.6)],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3),
                                    blurRadius: 20, offset: const Offset(0, 8))],
                              ),
                              child: const Icon(Icons.directions_car_rounded,
                                  color: Colors.black, size: 32),
                            ),
                            const SizedBox(height: 16),
                            Text('OmniDrive AI', style: GoogleFonts.inter(
                              fontSize: 26, fontWeight: FontWeight.w800,
                              color: kTextPrimary, letterSpacing: -0.8,
                            )),
                            const SizedBox(height: 6),
                            Text('Your Car. Your City. Your Market.',
                              style: kBody(13, color: kTextMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Role cards ─────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Choose your role', style: kLabel(12,
                          color: kTextMuted, fw: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ..._roles.map((role) => _RoleCard(
                          role: role,
                          selected: _selected == role.id,
                          onTap: () => setState(() => _selected = role.id),
                        )),
                        const SizedBox(height: 20),
                        // ── Continue button ────────────────────────────────
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity, height: 54,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accent, accent.withValues(alpha: 0.7)],
                              begin: Alignment.centerLeft, end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35),
                                blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (_) =>
                                    LoginScreen(preselectedRole: _selected == 'vendor' ? 1 : _selected == 'rider' ? 2 : 0))),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Continue as ${_roles.firstWhere((r) => r.id == _selected).label}',
                                      style: GoogleFonts.inter(fontSize: 15,
                                        fontWeight: FontWeight.w700, color: Colors.black)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded,
                                        color: Colors.black, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => const LoginScreen())),
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: kBody(13, color: kTextMuted),
                                children: [TextSpan(text: 'Sign In',
                                  style: kBody(13, color: kCyan, fw: FontWeight.w600))],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleData {
  final String id, label, subtitle;
  final IconData icon;
  final Color accent;
  const _RoleData(this.id, this.label, this.subtitle, this.icon, this.accent);
}

class _RoleCard extends StatelessWidget {
  final _RoleData role;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard({required this.role, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? role.accent.withValues(alpha: 0.1) : kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? role.accent : kBorder,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: role.accent.withValues(alpha: 0.15),
                  blurRadius: 20, offset: const Offset(0, 6))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: role.accent.withValues(alpha: selected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(role.icon, color: role.accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.label, style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: selected ? kTextPrimary : kTextSecondary)),
                  const SizedBox(height: 3),
                  Text(role.subtitle, style: kBody(12, color: kTextMuted)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? role.accent : Colors.transparent,
                border: Border.all(
                  color: selected ? role.accent : kBorder, width: 2),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.black, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
