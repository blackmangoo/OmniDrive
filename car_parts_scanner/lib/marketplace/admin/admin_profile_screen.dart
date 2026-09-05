import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import '../../core/motion/motion_tappable.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});
  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  AppUser? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final user = await MarketplaceService.fetchCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
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
        title: Text('Admin Panel', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: kError))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(
                  child: Column(children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kError.withValues(alpha: 0.15),
                        border: Border.all(color: kError.withValues(alpha: 0.4), width: 2),
                      ),
                      child: Icon(Icons.admin_panel_settings_rounded, color: kError, size: 44),
                    ),
                    SizedBox(height: 14),
                    Text(_user?.fullName ?? '—', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(_user?.email ?? '—', style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: kError.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kError.withValues(alpha: 0.3)),
                      ),
                      child: Text('🔐  Admin', style: GoogleFonts.inter(color: kError, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
                SizedBox(height: 40),
                TappableScale(
                  onTap: () async => await Supabase.instance.client.auth.signOut(),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kError.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kError.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Icon(Icons.logout_rounded, color: kError, size: 22),
                      SizedBox(width: 14),
                      Text('Sign Out', style: GoogleFonts.inter(color: kError, fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ),
    );
  }
}
