import 'package:flutter/material.dart';
import 'main.dart' show cameras;
import 'image_search_screen.dart';
import 'performance/performance_home_screen.dart';

const _kBg = Color(0xFF0A0A0F);
const _kAccent = Color(0xFF4FC3F7);
const _kNavBg = Color(0xFF0E0E18);

/// The main app shell after successful login — hosts the bottom nav bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      ImageSearchScreen(cameras: cameras),
      const PerformanceHomeScreen(),
    ];

    return Scaffold(
      backgroundColor: _kBg,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _kNavBg,
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: _kAccent.withOpacity(0.15),
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.search_rounded, color: Colors.white38),
              selectedIcon: Icon(Icons.search_rounded, color: _kAccent),
              label: 'Scanner',
            ),
            NavigationDestination(
              icon: Icon(Icons.speed_rounded, color: Colors.white38),
              selectedIcon: Icon(Icons.speed_rounded, color: _kAccent),
              label: 'Performance',
            ),
          ],
        ),
      ),
    );
  }
}
