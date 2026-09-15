import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import 'orders_screen.dart';
import 'package:car_parts_scanner/core/theme/app_colors.dart';



class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});
  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  AppUser? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = await MarketplaceService.fetchCurrentUser();
    if (mounted) setState(() { _user = user; _loading = false; });
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kError, size: 24),
            SizedBox(width: 10),
            Text('Delete Account', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete your account and all associated data? This action cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kError,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await MarketplaceService.deleteUserAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        automaticallyImplyLeading: false,
        title: Text('My Profile', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: kAccent))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── Avatar + name ──────────────────────────────────────────
                Center(
                  child: Column(children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kAccent.withValues(alpha: 0.15),
                        border: Border.all(color: kAccent.withValues(alpha: 0.4), width: 2),
                      ),
                      child: Icon(Icons.person_rounded, color: kAccent, size: 44),
                    ),
                    SizedBox(height: 14),
                    Text(_user?.fullName ?? '—',
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(_user?.email ?? '—', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
                    SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: kAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kAccent.withValues(alpha: 0.3)),
                      ),
                      child: Text('Customer', style: GoogleFonts.inter(color: kAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),

                SizedBox(height: 32),

                // ── Menu ───────────────────────────────────────────────────
                _menuItem(icon: Icons.receipt_long_rounded, label: 'My Orders',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrdersScreen()))),
                _menuItem(icon: Icons.location_on_outlined, label: 'Saved Addresses', onTap: () {}),
                _menuItem(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () {}),

                SizedBox(height: 24),
                Divider(color: kBorder),
                SizedBox(height: 16),

                // ── Logout ─────────────────────────────────────────────────
                GestureDetector(
                  onTap: _logout,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(children: [
                      Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 22),
                      SizedBox(width: 14),
                      Text('Sign Out', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),

                SizedBox(height: 12),

                // ── Delete Account (Store Compliance) ──────────────────────
                GestureDetector(
                  onTap: _confirmDeleteAccount,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kError.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kError.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Icon(Icons.delete_forever_rounded, color: kError, size: 22),
                      SizedBox(width: 14),
                      Text('Delete Account', style: GoogleFonts.inter(color: kError, fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ),
    );
  }

  Widget _menuItem({required IconData icon, required String label, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: kCardDeco(),
          child: Row(children: [
            Icon(icon, color: kAccent, size: 22),
            SizedBox(width: 14),
            Expanded(child: Text(label, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15))),
            Icon(Icons.chevron_right_rounded, color: (AppColors.textMuted.withValues(alpha: 0.5))),
          ]),
        ),
      );
}
