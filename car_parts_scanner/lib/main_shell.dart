import 'package:flutter/material.dart';
import 'main.dart' show cameras;
import 'image_search_screen.dart';
import 'performance/performance_home_screen.dart';
import 'package:car_parts_scanner/core/theme/app_colors.dart';



Color get _kBg => AppColors.background;
Color get _kAccent => AppColors.cyan;
Color get _kNavBg => AppColors.surface;

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
      PerformanceHomeScreen(),
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
            top: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.06)),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: _kAccent.withValues(alpha: 0.15),
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.search_rounded, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.search_rounded, color: _kAccent),
              label: 'Scanner',
            ),
            NavigationDestination(
              icon: Icon(Icons.speed_rounded, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.speed_rounded, color: _kAccent),
              label: 'Performance',
            ),
          ],
        ),
      ),
    );
  }
}
