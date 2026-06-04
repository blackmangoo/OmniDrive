import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import '../../main.dart' show cameras;
import '../../image_search_screen.dart';
import '../../performance/performance_home_screen.dart';
import '../marketplace_constants.dart';
import '../marketplace_service.dart';
import 'marketplace_home_screen.dart';
import 'cart_screen.dart';
import 'customer_profile_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _idx = 0;
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    final count = await MarketplaceService.getCartCount();
    if (mounted) setState(() => _cartCount = count);
  }

  List<Widget> get _screens => [
        const MarketplaceHomeScreen(),
        ImageSearchScreen(cameras: cameras),
        const CartScreen(),
        const PerformanceHomeScreen(),
        const CustomerProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kSurface,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: kAccent.withValues(alpha: 0.15),
          selectedIndex: _idx,
          onDestinationSelected: (i) {
            setState(() => _idx = i);
            if (i == 2) _loadCartCount(); // refresh cart count when tab tapped
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined, color: Colors.white38),
              selectedIcon: Icon(Icons.storefront_rounded, color: kAccent),
              label: 'Market',
            ),
            const NavigationDestination(
              icon: Icon(Icons.document_scanner_outlined, color: Colors.white38),
              selectedIcon: Icon(Icons.document_scanner_rounded, color: kAccent),
              label: 'Scanner',
            ),
            NavigationDestination(
              icon: badges.Badge(
                showBadge: _cartCount > 0,
                badgeContent: Text('$_cartCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                badgeStyle: const badges.BadgeStyle(badgeColor: kError),
                child: const Icon(Icons.shopping_cart_outlined, color: Colors.white38),
              ),
              selectedIcon: badges.Badge(
                showBadge: _cartCount > 0,
                badgeContent: Text('$_cartCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                badgeStyle: const badges.BadgeStyle(badgeColor: kError),
                child: const Icon(Icons.shopping_cart_rounded, color: kAccent),
              ),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.speed_outlined, color: Colors.white38),
              selectedIcon: Icon(Icons.speed_rounded, color: kAccent),
              label: 'Speed',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: Colors.white38),
              selectedIcon: Icon(Icons.person_rounded, color: kAccent),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
