import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../marketplace_constants.dart';
import '../marketplace_service.dart';
import '../../core/motion/motion_stagger.dart';
import '../../core/motion/motion_tappable.dart';

class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  List<Map<String, dynamic>> _pendingUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadApprovals();
  }

  Future<void> _loadApprovals() async {
    if (mounted) setState(() => _loading = true);
    final users = await MarketplaceService.fetchPendingApprovals();
    if (mounted) {
      setState(() {
        _pendingUsers = users;
        _loading = false;
      });
    }
  }

  Future<void> _approveUser(String userId, String role) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: kAdmin),
      ),
    );

    try {
      await MarketplaceService.approveUser(userId, role);
      
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      // Show success checkmark dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessFeedbackDialog(),
      );

      // Wait 1.5s for success feedback
      await Future.delayed(Duration(milliseconds: 1500));

      if (!mounted) return;
      Navigator.pop(context); // Dismiss success feedback dialog

      _loadApprovals(); // Reload list
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve user.'),
          backgroundColor: kError,
        ),
      );
    }
  }

  Future<void> _rejectUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: kBorder),
        ),
        title: Text(
          'Reject Registration?',
          style: kHeadline(18, color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to reject and permanently block this registration? This will delete the user account.',
          style: kBody(14, color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: kBody(14, color: kTextMuted),
            ),
          ),
          TappableScale(
            onTap: () => Navigator.pop(context, true),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: kError,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Reject & Block', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: kAdmin),
      ),
    );

    try {
      await MarketplaceService.rejectUser(userId);
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User registration rejected.'),
          backgroundColor: kWarning,
        ),
      );

      _loadApprovals(); // Reload list
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject user.'),
          backgroundColor: kError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Registration Approvals',
          style: kHeadline(22, color: Colors.white),
        ),
        actions: [
          TappableScale(
            onTap: _loadApprovals,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.refresh_rounded, color: Colors.white70),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: kAdmin))
          : RefreshIndicator(
              color: kAdmin,
              backgroundColor: kSurface,
              onRefresh: _loadApprovals,
              child: _pendingUsers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _pendingUsers.length,
                      itemBuilder: (context, index) {
                        final item = _pendingUsers[index];
                        return StaggeredEntrance(
                          index: index,
                          child: _buildApprovalCard(item),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kSurface,
                  border: Border.all(color: kBorder),
                ),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  color: kCyan,
                  size: 64,
                ),
              )
              .animate()
              .scaleXY(begin: 0.8, end: 1.0, duration: 600.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 500.ms),
              SizedBox(height: 20),
              Text(
                'All Caught Up!',
                style: kHeadline(18, color: Colors.white),
              ),
              SizedBox(height: 6),
              Text(
                'No pending registration requests.',
                style: kBody(13, color: kTextMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> item) {
    final String userId = item['id'] as String;
    final String role = item['role'] as String;
    final String name = item['full_name'] as String? ?? 'No Name';
    final String email = item['email'] as String? ?? 'No Email';
    final String phone = item['phone'] as String? ?? 'No Phone';
    final String? shopName = item['shop_name'] as String?;
    final String? location = item['location'] as String?;

    final isVendor = role == 'vendor';
    final roleAccent = isVendor ? kVendor : kRider;
    final roleName = isVendor ? 'Vendor' : 'Rider';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: kGlowDeco(roleAccent, radius: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header section
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: kSurface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isVendor ? Icons.storefront_rounded : Icons.directions_bike_rounded,
                        color: roleAccent,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        isVendor ? (shopName ?? 'Vendor Shop') : 'Rider Account',
                        style: kHeadline(15, color: Colors.white),
                      ),
                    ],
                  ),
                  kStatusPill(roleName, roleAccent),
                ],
              ),
            ),

            // Card Body (Details)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isVendor) ...[
                    if (location != null && location.isNotEmpty) ...[
                      _buildDetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: location,
                      ),
                      SizedBox(height: 10),
                    ],
                    _buildDetailRow(
                      icon: Icons.person_outline,
                      label: 'Owner Name',
                      value: name,
                    ),
                  ] else ...[
                    _buildDetailRow(
                      icon: Icons.person_outline,
                      label: 'Rider Name',
                      value: name,
                    ),
                  ],
                  SizedBox(height: 10),
                  _buildDetailRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email Address',
                    value: email,
                  ),
                  SizedBox(height: 10),
                  _buildDetailRow(
                    icon: Icons.phone_android_rounded,
                    label: 'Phone Number',
                    value: phone,
                  ),
                ],
              ),
            ),

            // Action Buttons
            Container(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TappableScale(
                      onTap: () => _rejectUser(userId),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kBorder),
                        ),
                        child: Text(
                          'Reject',
                          style: GoogleFonts.inter(
                            color: kError,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TappableScale(
                      onTap: () => _approveUser(userId, role),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: roleAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Approve',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kTextMuted, size: 16),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: kLabel(10, color: kTextMuted),
              ),
              SizedBox(height: 1),
              Text(
                value,
                style: kBody(13, color: kTextPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuccessFeedbackDialog extends StatelessWidget {
  const _SuccessFeedbackDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: kBorder),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSuccess,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: Colors.black,
                size: 40,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            SizedBox(height: 24),
            Text(
              'User Approved!',
              style: kHeadline(18, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'The account has been activated successfully.',
              style: kBody(13, color: kTextSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
