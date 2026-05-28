import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});
  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg, automaticallyImplyLeading: false,
        title: Text('My Profile', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kRider))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── Avatar ─────────────────────────────────────────────────
                Center(
                  child: Column(children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kRider.withValues(alpha: 0.15),
                        border: Border.all(color: kRider.withValues(alpha: 0.4), width: 2),
                      ),
                      child: const Icon(Icons.delivery_dining_rounded, color: kRider, size: 44),
                    ),
                    const SizedBox(height: 14),
                    Text(_user?.fullName ?? '—', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_user?.email ?? '—', style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: kRider.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kRider.withValues(alpha: 0.3)),
                      ),
                      child: Text('🏍️  Rider', style: GoogleFonts.inter(color: kRider, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),

                const SizedBox(height: 32),

                // ── Info cards ─────────────────────────────────────────────
                _infoCard(icon: Icons.phone_outlined, label: 'Phone', value: _user?.phone ?? 'Not set'),
                _infoCard(icon: Icons.location_on_outlined, label: 'Address', value: _user?.address ?? 'Not set'),

                const SizedBox(height: 32),

                // ── Logout ─────────────────────────────────────────────────
                GestureDetector(
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

  Widget _infoCard({required IconData icon, required String label, required String value}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: kCardDeco(),
        child: Row(children: [
          Icon(icon, color: kRider, size: 22),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
          ]),
        ]),
      );
}
