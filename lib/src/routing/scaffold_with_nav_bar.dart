import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              index: 0,
              icon: Icons.home_outlined,
              active: navigationShell.currentIndex == 0,
            ),
            _buildNavItem(
              context,
              index: 1,
              icon: Icons.bar_chart_rounded,
              active: navigationShell.currentIndex == 1,
            ),

            // Center High-Profile Button (Shield with Plus)
            // Center High-Profile Button (Figma Style)
            GestureDetector(
              onTap: () => _onTap(context, 2),
              child: Container(
                width:
                    60, // Adjusted size slightly smaller based on image suggestion
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9), // Light Grey background
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1), // Soft shadow
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dark Shield
                    const Icon(
                      Icons.shield,
                      color: Color(0xFF1E293B), // Dark Grey
                      size: 40, // Scaled down with container
                    ),
                    // White Plus
                    const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            _buildNavItem(
              context,
              index: 3,
              icon: Icons.group_outlined,
              active: navigationShell.currentIndex == 3,
            ),
            _buildNavItem(
              context,
              index: 4,
              icon: Icons.settings_outlined,
              active: navigationShell.currentIndex == 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context,
      {required int index, required IconData icon, required bool active}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      onPressed: () => _onTap(context, index),
      icon: Icon(
        icon,
        color: active
            ? const Color(0xFF0D9488)
            : (isDark ? Colors.grey.shade600 : const Color(0xFF94A3B8)),
        size: 28,
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      // A common pattern when using bottom navigation bars is to support
      // navigating to the initial location when tapping the item that is
      // already active. This example demonstrates how to support this behavior,
      // using the initialLocation parameter of goBranch.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
