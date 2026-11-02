import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/girly_theme.dart';
import '../../../../core/widgets/calico_ui_kit.dart';

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
    final isGirly = GirlyThemeProvider.isGirly(context);
    final navBg = isGirly
        ? GirlyColors.navBarBg.withAlpha(242)
        : AppColors.calicoBlack.withAlpha(242);
    final navBorder = isGirly
        ? GirlyColors.primary.withAlpha(100)
        : AppColors.primary.withAlpha(65);
    final shadowColor = isGirly
        ? GirlyColors.primaryDark.withAlpha(80)
        : AppColors.calicoBlack.withAlpha(95);
    final glowColor = isGirly
        ? GirlyColors.primary.withAlpha(55)
        : AppColors.primary.withAlpha(28);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: navBg,
            borderRadius: BorderRadius.circular(isGirly ? 32 : 28),
            border: Border.all(
              color: navBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: glowColor,
                blurRadius: 14,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _NavBarItem(
                icon: Icons.auto_awesome_mosaic_outlined,
                activeIcon: Icons.auto_awesome_mosaic_rounded,
                label: 'Dex',
                isSelected: currentIndex == 1,
                onTap: () => onTabSelected(1),
              ),
              const SizedBox(width: 64),
              _NavBarItem(
                icon: Icons.emoji_events_outlined,
                activeIcon: Icons.emoji_events_rounded,
                label: 'Ranks',
                isSelected: currentIndex == 2,
                onTap: () => onTabSelected(2),
              ),
              _NavBarItem(
                icon: Icons.pets_outlined,
                activeIcon: Icons.pets_rounded,
                label: 'Account',
                isSelected: currentIndex == 3,
                onTap: () => onTabSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
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
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _triggerController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _tiltAnim;

  @override
  void initState() {
    super.initState();
    _triggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.24,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.24,
          end: 0.94,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.94,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
    ]).animate(_triggerController);

    _tiltAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.12),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.12, end: 0.10),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.10, end: 0.0),
        weight: 35,
      ),
    ]).animate(_triggerController);
  }

  @override
  void didUpdateWidget(covariant _NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _triggerController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _triggerController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    _triggerController.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isGirly = GirlyThemeProvider.isGirly(context);

    final iconColor = isSelected
        ? (isGirly ? GirlyColors.navSelected : AppColors.primary)
        : (isGirly ? GirlyColors.navMuted : AppColors.calicoMuted);
    final labelColor = isSelected
        ? (isGirly ? GirlyColors.highlightPink : Colors.white)
        : (isGirly ? GirlyColors.navMuted : AppColors.calicoMuted);
    final barColor = isGirly ? GirlyColors.highlightPink : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CalicoAnimatedBar(
              isActive: isSelected,
              activeWidth: 20,
              activeColor: barColor,
            ),
            AnimatedBuilder(
              animation: _triggerController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _tiltAnim.value,
                  child: Transform.scale(scale: _scaleAnim.value, child: child),
                );
              },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: isSelected ? 1.0 : 0.72,
                child: Icon(
                  isSelected ? widget.activeIcon : widget.icon,
                  size: 22,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: labelColor,
                letterSpacing: 0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
