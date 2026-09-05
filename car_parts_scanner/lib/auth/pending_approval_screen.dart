import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../marketplace/marketplace_service.dart';
import 'auth_gate.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_shadows.dart';
import '../core/motion/motion_tappable.dart';

class PendingApprovalScreen extends StatefulWidget {
  final String? role;
  final VoidCallback? onCheckStatus;

  const PendingApprovalScreen({
    super.key,
    this.role,
    this.onCheckStatus,
  });

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _checkingStatus = false;
  bool _loggingOut = false;

  Future<void> _checkStatus() async {
    if (_checkingStatus) return;
    setState(() => _checkingStatus = true);

    try {
      final isApproved = await MarketplaceService.isUserApproved();
      if (!mounted) return;

      if (isApproved) {
        widget.onCheckStatus?.call();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => AuthGate()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your account is still under review.',
              style: AppTypography.body.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check status. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingStatus = false);
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);

    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AuthGate()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? 'N/A';
    final roleText = widget.role != null
        ? widget.role!.substring(0, 1).toUpperCase() + widget.role!.substring(1)
        : 'User';

    final accentColor = widget.role == 'vendor'
        ? AppColors.vendorDark
        : widget.role == 'rider'
            ? AppColors.rider
            : AppColors.cyan;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Spacer(),
              
              // Hourglass icon with pulsing neon glow
              Center(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                      width: 2,
                    ),
                    boxShadow: AppShadows.roleGlow(accentColor),
                  ),
                  child: Icon(
                    Icons.hourglass_empty_rounded,
                    color: accentColor,
                    size: 64,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(begin: Offset(0.92, 0.92), end: Offset(1.08, 1.08), duration: 1500.ms, curve: Curves.easeInOutCubic),
              ),
              SizedBox(height: 32),

              // Title
              Text(
                'Account Under Review',
                textAlign: TextAlign.center,
                style: AppTypography.display.copyWith(fontSize: 26),
              ),
              SizedBox(height: 12),

              // Description
              Text(
                'Your registration request has been submitted. Our administrative team will verify your details and activate your account shortly.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              SizedBox(height: 40),

              // Details Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppSpacing.rLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      label: 'Account Email',
                      value: email,
                      icon: Icons.alternate_email_rounded,
                      accentColor: accentColor,
                    ),
                    Divider(color: AppColors.border, height: 28),
                    _buildDetailRow(
                      label: 'Requested Role',
                      value: roleText,
                      icon: widget.role == 'vendor'
                          ? Icons.storefront_rounded
                          : Icons.directions_bike_rounded,
                      accentColor: accentColor,
                    ),
                  ],
                ),
              ),

              Spacer(),

              // Check Status Button
              SizedBox(
                height: 54,
                width: double.infinity,
                child: TappableScale(
                  onTap: _checkingStatus || _loggingOut ? null : _checkStatus,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(AppSpacing.rLg),
                      boxShadow: AppShadows.roleGlow(accentColor),
                    ),
                    child: Center(
                      child: _checkingStatus
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Check Status',
                              style: AppTypography.label.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 14),

              // Log Out Button
              SizedBox(
                height: 54,
                width: double.infinity,
                child: TappableScale(
                  onTap: _checkingStatus || _loggingOut ? null : _logout,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSpacing.rLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: _loggingOut
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.textPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Log Out',
                              style: AppTypography.label.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: accentColor.withValues(alpha: 0.8), size: 20),
        SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption,
            ),
            SizedBox(height: 3),
            Text(
              value,
              style: AppTypography.title.copyWith(fontSize: 15),
            ),
          ],
        ),
      ],
    );
  }
}
