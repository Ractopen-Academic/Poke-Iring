import 'package:flutter/material.dart';

import '../../data/services/quick_snap_position_service_impl.dart';
import '../../domain/services/quick_snap_position_service.dart';
import 'cute_cat_camera_painter.dart';

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

  static const double _buttonSize = 58.0;
  static const double _margin = 12.0;

  Offset? _currentOffset;
  bool _isDragging = false;
  bool _isInitialized = false;
  double _totalDragDistance = 0.0;
  DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);

  void _fireTap() {
    final now = DateTime.now();
    if (now.difference(_lastTapTime).inMilliseconds < 450) return;
    _lastTapTime = now;
    widget.onTap();
  }

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

  void _onPanStart(DragStartDetails details) {
    _totalDragDistance = 0.0;
  }

  void _onPanUpdate(
    DragUpdateDetails details,
    Size screenSize,
    EdgeInsets padding,
  ) {
    if (_snapController.isAnimating) _snapController.stop();

    _totalDragDistance += details.delta.distance;
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
    if (_totalDragDistance < 8.0) {
      _fireTap();
      return;
    }

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
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final parentWidth =
              constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final parentHeight =
              constraints.maxHeight.isFinite && constraints.maxHeight > 0
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height;
          final parentSize = Size(parentWidth, parentHeight);
          final padding = MediaQuery.paddingOf(context);

          if (!_isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initPosition(parentSize, padding);
            });
          }

          final defaultOffset = Offset(
            parentSize.width - _buttonSize - _margin,
            parentSize.height * 0.65,
          );
          final offset = _currentOffset ?? defaultOffset;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: offset.dx,
                top: offset.dy,
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: (details) =>
                      _onPanUpdate(details, parentSize, padding),
                  onPanEnd: (details) =>
                      _onPanEnd(details, parentSize, padding),
                  onTap: _fireTap,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 140),
                    scale: _isDragging ? 1.10 : 1.0,
                    child: const RepaintBoundary(
                      child: SizedBox(
                        width: _buttonSize,
                        height: _buttonSize,
                        child: CustomPaint(painter: CuteCatCameraPainter()),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
