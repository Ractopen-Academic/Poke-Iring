import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/services/quick_snap_position_service_impl.dart';
import '../../domain/services/quick_snap_position_service.dart';

class FloatingSnapIringButton extends StatefulWidget {
  final VoidCallback onTap;
  final QuickSnapPositionService? positionService;

  const FloatingSnapIringButton({
    super.key,
    required this.onTap,
    this.positionService,
  });

  @override
  State<FloatingSnapIringButton> createState() =>
      _FloatingSnapIringButtonState();
}

class _FloatingSnapIringButtonState extends State<FloatingSnapIringButton>
    with SingleTickerProviderStateMixin {
  late final QuickSnapPositionService _positionService;
  late final AnimationController _snapController;
  Animation<Offset>? _snapAnimation;

  static const double _buttonSize = 54.0;
  static const double _margin = 12.0;

  Offset? _currentOffset;
  bool _isDragging = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _positionService = widget.positionService ?? QuickSnapPositionServiceImpl();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  Future<void> _initPosition(Size screenSize, EdgeInsets padding) async {
    if (_isInitialized) return;
    _isInitialized = true;

    final saved = await _positionService.loadPosition();
    if (!mounted) return;

    final minX = _margin;
    final maxX = screenSize.width - _buttonSize - _margin;
    final minY = padding.top + 60.0;
    final maxY = screenSize.height - padding.bottom - 120.0;

    final initialX = saved.xFraction <= 0.5 ? minX : maxX;
    final initialY = (saved.yFraction * screenSize.height).clamp(minY, maxY);

    setState(() {
      _currentOffset = Offset(initialX, initialY);
    });
  }

  void _onPanUpdate(
    DragUpdateDetails details,
    Size screenSize,
    EdgeInsets padding,
  ) {
    if (_snapController.isAnimating) _snapController.stop();

    setState(() {
      _isDragging = true;
      final current = _currentOffset ?? Offset.zero;
      final minX = _margin;
      final maxX = screenSize.width - _buttonSize - _margin;
      final minY = padding.top + 60.0;
      final maxY = screenSize.height - padding.bottom - 120.0;

      final newX = (current.dx + details.delta.dx).clamp(minX, maxX);
      final newY = (current.dy + details.delta.dy).clamp(minY, maxY);
      _currentOffset = Offset(newX, newY);
    });
  }

  void _onPanEnd(DragEndDetails details, Size screenSize, EdgeInsets padding) {
    _isDragging = false;
    final current = _currentOffset ?? Offset.zero;
    final minX = _margin;
    final maxX = screenSize.width - _buttonSize - _margin;
    final minY = padding.top + 60.0;
    final maxY = screenSize.height - padding.bottom - 120.0;

    // Snap to nearest edge (left or right)
    final targetX = (current.dx + _buttonSize / 2 < screenSize.width / 2)
        ? minX
        : maxX;
    final targetY = current.dy.clamp(minY, maxY);
    final targetOffset = Offset(targetX, targetY);

    _snapAnimation = Tween<Offset>(begin: current, end: targetOffset).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );

    void listener() {
      if (mounted) {
        setState(() {
          _currentOffset = _snapAnimation!.value;
        });
      }
    }

    _snapAnimation!.addListener(listener);
    _snapController.forward(from: 0.0).then((_) {
      _snapAnimation?.removeListener(listener);
      // Persist normalized coordinates
      final xFraction = targetX == minX ? 0.0 : 1.0;
      final yFraction = (targetY / screenSize.height).clamp(0.0, 1.0);
      _positionService.savePosition(
        QuickSnapPosition(xFraction: xFraction, yFraction: yFraction),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;

    if (!_isInitialized) {
      _initPosition(screenSize, padding);
      return const SizedBox.shrink();
    }

    final offset =
        _currentOffset ??
        Offset(
          screenSize.width - _buttonSize - _margin,
          screenSize.height * 0.65,
        );

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) => _onPanUpdate(details, screenSize, padding),
        onPanEnd: (details) => _onPanEnd(details, screenSize, padding),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: _isDragging ? 1.08 : 1.0,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            elevation: _isDragging ? 8 : 4,
            shadowColor: Colors.black.withAlpha(90),
            child: Container(
              width: _buttonSize,
              height: _buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFA726),
                    AppColors.primary,
                    Color(0xFFF57C00),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 2.2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  Positioned(
                    top: 11,
                    right: 14,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.white70,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
