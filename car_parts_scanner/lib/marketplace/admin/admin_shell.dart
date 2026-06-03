import 'package:flutter/material.dart';
import '../marketplace_constants.dart';
import 'admin_orders_screen.dart';
import 'admin_approvals_screen.dart';
import 'admin_profile_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _idx = 0;

  final List<Widget> _screens = const [
    AdminOrdersScreen(),
    AdminApprovalsScreen(),
    AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E18),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
          selectedIndex: _idx,
          onDestinationSelected: (i) => setState(() => _idx = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined, color: Colors.white38),
              selectedIcon: Icon(Icons.admin_panel_settings_rounded, color: kError),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.verified_outlined, color: Colors.white38),
              selectedIcon: Icon(Icons.verified_rounded, color: kError),
              label: 'Approvals',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: Colors.white38),
              selectedIcon: Icon(Icons.person_rounded, color: kError),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

