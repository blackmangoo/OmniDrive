import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import '../../core/motion/motion_tappable.dart';
import '../../core/motion/motion_counter.dart';
import 'package:car_parts_scanner/core/theme/app_colors.dart';



class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});
  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  AppUser? _user;
  VendorProfile? _vendor;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final user   = await MarketplaceService.fetchCurrentUser();
    final vendor = await MarketplaceService.fetchVendorProfile();
    if (mounted) {
      setState(() {
        _user = user;
        _vendor = vendor;
        _loading = false;
      });
    }
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
            Text('Delete Vendor Account', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete your shop account and all listed catalog items? This action cannot be undone.',
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
        backgroundColor: kBg, automaticallyImplyLeading: false,
        title: Text('Shop Profile', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: kAccent))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── Shop card ────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: kCardDeco(),
                  child: Column(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kAccent.withValues(alpha: 0.15),
                        border: Border.all(color: kAccent.withValues(alpha: 0.4), width: 2),
                      ),
                      child: Icon(Icons.storefront_rounded, color: kAccent, size: 36),
                    ),
                    SizedBox(height: 12),
                    Text(_vendor?.shopName ?? 'Your Shop',
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                    if (_vendor?.location != null) ...[
                      SizedBox(height: 4),
                      Text('📍 ${_vendor!.location!}', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
                    ],
                    SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _statChip(
                        MotionCounter(
                          value: _vendor?.totalOrders ?? 0,
                          style: GoogleFonts.inter(color: kAccent, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        'Orders',
                      ),
                      SizedBox(width: 16),
                      _statChip(
                        MotionCounter(
                          value: _vendor?.rating ?? 0.0,
                          decimals: 1,
                          suffix: ' ⭐',
                          style: GoogleFonts.inter(color: kAccent, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        'Rating',
                      ),
                      SizedBox(width: 16),
                      _statChip(
                        Text(_vendor?.isVerified == true ? '✅' : '⏳',
                            style: GoogleFonts.inter(color: kAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                        _vendor?.isVerified == true ? 'Verified' : 'Pending',
                      ),
                    ]),
                  ]),
                ),

                SizedBox(height: 24),

                // ── Account Info ─────────────────────────────────────────
                _sectionHeader('Account'),
                _infoRow(Icons.person_outline_rounded, 'Email', _user?.email ?? '—'),
                _infoRow(Icons.phone_outlined, 'Phone', _user?.phone ?? '—'),
                _infoRow(Icons.info_outline_rounded, 'Shop Description', _vendor?.shopDescription ?? 'No description'),

                SizedBox(height: 24),

                // ── Logout ───────────────────────────────────────────────
                TappableScale(
                  onTap: () async => await Supabase.instance.client.auth.signOut(),
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
                TappableScale(
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

  Widget _statChip(Widget child, String label) => Column(children: [
    child,
    SizedBox(height: 4),
    Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
  ]);

  Widget _sectionHeader(String t) => Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: Text(t, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
  );

  Widget _infoRow(IconData icon, String label, String value) => Container(
    margin: EdgeInsets.only(bottom: 10),
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: kCardDeco(),
    child: Row(children: [
      Icon(icon, color: kAccent, size: 20),
      SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
          SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 3),
        ]),
      ),
    ]),
  );
}
