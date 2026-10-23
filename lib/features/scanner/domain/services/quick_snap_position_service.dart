class QuickSnapPosition {
  final double xFraction;
  final double yFraction;

  const QuickSnapPosition({required this.xFraction, required this.yFraction});

  static const defaultPosition = QuickSnapPosition(
    xFraction: 1.0,
    yFraction: 0.65,
  );
}

abstract class QuickSnapPositionService {
  Future<QuickSnapPosition> loadPosition();
  Future<void> savePosition(QuickSnapPosition position);
}
