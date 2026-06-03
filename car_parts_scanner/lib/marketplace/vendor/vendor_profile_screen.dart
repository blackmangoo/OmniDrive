import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import '../../core/motion/motion_tappable.dart';
import '../../core/motion/motion_counter.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg, automaticallyImplyLeading: false,
        title: Text('Shop Profile', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kVendor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── Shop card ────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: kGlowCard(kVendor),
                  child: Column(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kVendor.withValues(alpha: 0.15),
                        border: Border.all(color: kVendor.withValues(alpha: 0.4), width: 2),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: kVendor, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(_vendor?.shopName ?? 'Your Shop',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    if (_vendor?.location != null) ...[
                      const SizedBox(height: 4),
                      Text('📍 ${_vendor!.location!}', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
                    ],
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _statChip(
                        MotionCounter(
                          value: _vendor?.totalOrders ?? 0,
                          style: GoogleFonts.inter(color: kVendor, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        'Orders',
                      ),
                      const SizedBox(width: 16),
                      _statChip(
                        MotionCounter(
                          value: _vendor?.rating ?? 0.0,
                          decimals: 1,
                          suffix: ' ⭐',
                          style: GoogleFonts.inter(color: kVendor, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        'Rating',
                      ),
                      const SizedBox(width: 16),
                      _statChip(
                        Text(_vendor?.isVerified == true ? '✅' : '⏳',
                            style: GoogleFonts.inter(color: kVendor, fontSize: 16, fontWeight: FontWeight.bold)),
                        _vendor?.isVerified == true ? 'Verified' : 'Pending',
                      ),
                    ]),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── Account Info ─────────────────────────────────────────
                _sectionHeader('Account'),
                _infoRow(Icons.person_outline_rounded, 'Email', _user?.email ?? '—'),
                _infoRow(Icons.phone_outlined, 'Phone', _user?.phone ?? '—'),
                _infoRow(Icons.info_outline_rounded, 'Shop Description', _vendor?.shopDescription ?? 'No description'),

                const SizedBox(height: 24),

                // ── Logout ───────────────────────────────────────────────
                TappableScale(
                  onTap: () async => await Supabase.instance.client.auth.signOut(),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kError.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kError.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.logout_rounded, color: kError, size: 22),
                      const SizedBox(width: 14),
                      Text('Sign Out', style: GoogleFonts.inter(color: kError, fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ),
    );
  }

  Widget _statChip(Widget child, String label) => Column(children: [
    child,
    const SizedBox(height: 4),
    Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
  ]);

  Widget _sectionHeader(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
  );

  Widget _infoRow(IconData icon, String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: kCardDeco(),
    child: Row(children: [
      Icon(icon, color: kVendor, size: 20),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 3),
        ]),
      ),
    ]),
  );
}
