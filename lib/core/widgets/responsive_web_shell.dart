import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveWebShell extends StatelessWidget {
  final Widget child;
  static const double mobileBreakpoint = 500.0;
  static const double s25FeWidth = 412.0;
  static const double s25FeHeight = 892.0;

  const ResponsiveWebShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint) {
          return child;
        }

        final targetHeight = constraints.maxHeight < s25FeHeight + 40
            ? constraints.maxHeight * 0.96
            : s25FeHeight;

        return Scaffold(
          backgroundColor: const Color(0xFF141416),
          body: Center(
            child: Container(
              width: s25FeWidth,
              height: targetHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: const Color(0xFF2C2C30), width: 5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(140),
                    blurRadius: 36,
                    spreadRadius: 2,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(31),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(size: Size(s25FeWidth, targetHeight)),
                        child: child,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
