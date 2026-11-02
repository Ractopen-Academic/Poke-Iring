import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme_mode.dart';
import '../theme/girly_theme.dart';

/// Cycles between the Normal, Kawaii, and Dark app themes.
class GirlyThemeToggle extends StatefulWidget {
  const GirlyThemeToggle({super.key});

  @override
  State<GirlyThemeToggle> createState() => _GirlyThemeToggleState();
}

class _GirlyThemeToggleState extends State<GirlyThemeToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _spin;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _spin = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticFeedback.mediumImpact();
    await _controller.forward(from: 0.0);
    if (mounted) {
      await GirlyThemeProvider.of(context).toggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = GirlyThemeProvider.mode(context);
    final isGirly = mode == AppThemeMode.kawaii;
    final isDark = mode == AppThemeMode.dark;
    final background = isGirly
        ? GirlyColors.primaryLight
        : isDark
            ? const Color(0xFF29252D)
            : const Color(0xFFFFEFE0);
    final border = isGirly
        ? GirlyColors.primary
        : isDark
            ? const Color(0xFF514854)
            : const Color(0xFFFF8C1A);
    final foreground = isGirly
        ? GirlyColors.primaryDark
        : isDark
            ? const Color(0xFFFFC28A)
            : const Color(0xFFE06D00);
    final icon = isGirly
        ? '🎀'
        : isDark
            ? '🌙'
            : '🐱';
    final label = isGirly
        ? 'Kawaii'
        : isDark
            ? 'Dark'
            : 'Normal';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Transform.rotate(
            angle: _spin.value * 0.5, // gentle 180° tilt
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: background,
            border: Border.all(color: border, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: border.withAlpha(60),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: Text(
                  icon,
                  key: ValueKey<AppThemeMode>(mode),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                  letterSpacing: 0.1,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
