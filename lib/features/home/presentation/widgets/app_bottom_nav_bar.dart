import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      elevation: 6,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBarItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
              isSelected: currentIndex == 0,
              onTap: () => onTabSelected(0),
            ),
            _NavBarItem(
              icon: Icons.collections_bookmark_outlined,
              activeIcon: Icons.collections_bookmark,
              label: 'Dex',
              isSelected: currentIndex == 1,
              onTap: () => onTabSelected(1),
            ),
            const SizedBox(width: 56),
            _NavBarItem(
              icon: Icons.leaderboard_outlined,
              activeIcon: Icons.leaderboard,
              label: 'Ranks',
              isSelected: currentIndex == 2,
              onTap: () => onTabSelected(2),
            ),
            _NavBarItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Account',
              isSelected: currentIndex == 3,
              onTap: () => onTabSelected(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
