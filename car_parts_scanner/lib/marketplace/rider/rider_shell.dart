import 'package:flutter/material.dart';
import '../marketplace_constants.dart';
import 'rider_orders_screen.dart';
import 'rider_profile_screen.dart';

class RiderShell extends StatefulWidget {
  const RiderShell({super.key});
  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell> {
  int _idx = 0;

  final List<Widget> _screens = const [
    RiderOrdersScreen(),
    RiderProfileScreen(),
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
          indicatorColor: kRider.withValues(alpha: 0.15),
          selectedIndex: _idx,
          onDestinationSelected: (i) => setState(() => _idx = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.delivery_dining_outlined, color: Colors.white38),
              selectedIcon: Icon(Icons.delivery_dining_rounded, color: kRider),
              label: 'My Deliveries',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: Colors.white38),
              selectedIcon: Icon(Icons.person_rounded, color: kRider),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
