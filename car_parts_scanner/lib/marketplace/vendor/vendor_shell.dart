import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import '../marketplace_constants.dart';
import 'vendor_dashboard_screen.dart';
import 'vendor_catalogue_screen.dart';
import 'vendor_orders_screen.dart';
import 'vendor_profile_screen.dart';
import 'package:car_parts_scanner/core/theme/app_colors.dart';



class VendorShell extends StatefulWidget {
  const VendorShell({super.key});
  @override
  State<VendorShell> createState() => VendorShellState();
}

class VendorShellState extends State<VendorShell> {
  int _idx = 0;
  int _pendingOrders = 0;

  void updatePending(int count) {
    if (mounted) setState(() => _pendingOrders = count);
  }

  void setIndex(int index) {
    if (mounted) setState(() => _idx = index);
  }

  List<Widget> get _screens => [
        VendorDashboardScreen(),
        VendorCatalogueScreen(),
        VendorOrdersScreen(),
        VendorProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kSurface,
          border: Border(top: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.06))),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: kVendor.withValues(alpha: 0.15),
          selectedIndex: _idx,
          onDestinationSelected: (i) => setState(() => _idx = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.dashboard_rounded, color: kVendor),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.inventory_2_rounded, color: kVendor),
              label: 'Catalogue',
            ),
            NavigationDestination(
              icon: badges.Badge(
                showBadge: _pendingOrders > 0,
                badgeContent: Text('$_pendingOrders', style: TextStyle(color: AppColors.textPrimary, fontSize: 10)),
                badgeStyle: badges.BadgeStyle(badgeColor: kError),
                child: Icon(Icons.receipt_outlined, color: AppColors.textMuted),
              ),
              selectedIcon: badges.Badge(
                showBadge: _pendingOrders > 0,
                badgeContent: Text('$_pendingOrders', style: TextStyle(color: AppColors.textPrimary, fontSize: 10)),
                badgeStyle: badges.BadgeStyle(badgeColor: kError),
                child: Icon(Icons.receipt_rounded, color: kVendor),
              ),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.person_rounded, color: kVendor),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
