import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../marketplace_constants.dart';
import '../marketplace_service.dart';

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
    setState(() => _loading = true);
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
      builder: (_) => const Center(
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
        builder: (_) => const _SuccessFeedbackDialog(),
      );

      // Wait 1.5s for success feedback
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;
      Navigator.pop(context); // Dismiss success feedback dialog

      _loadApprovals(); // Reload list
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
          side: const BorderSide(color: kBorder),
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kError,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text('Reject & Block'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: kAdmin),
      ),
    );

    try {
      await MarketplaceService.rejectUser(userId);
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User registration rejected.'),
          backgroundColor: kWarning,
        ),
      );

      _loadApprovals(); // Reload list
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _loadApprovals,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAdmin))
          : RefreshIndicator(
              color: kAdmin,
              backgroundColor: kSurface,
              onRefresh: _loadApprovals,
              child: _pendingUsers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _pendingUsers.length,
                      itemBuilder: (context, index) {
                        final item = _pendingUsers[index];
                        return _buildApprovalCard(item);
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: kBorder),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: kTextMuted,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'All Caught Up!',
                style: kHeadline(18, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'No pending vendor or rider registration requests.',
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: kGlowDeco(roleAccent, radius: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      const SizedBox(width: 8),
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
              padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 10),
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
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email Address',
                    value: email,
                  ),
                  const SizedBox(height: 10),
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
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _rejectUser(userId),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: kBorder),
                        ),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveUser(userId, role),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: roleAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Approve',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: kLabel(10, color: kTextMuted),
              ),
              const SizedBox(height: 1),
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
        side: const BorderSide(color: kBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: kSuccess,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.black,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'User Approved!',
              style: kHeadline(18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'The account has been activated successfully.',
              style: kBody(13, color: kTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
