import 'package:flutter/material.dart';

/// Drawn stand-in for a live map. Replaced by a Maps SDK view once an API key
/// is available.
class MapPreview extends StatelessWidget {
  const MapPreview({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _MapPreviewPainter(Theme.of(context).colorScheme),
    child: const SizedBox.expand(),
  );
}

class _MapPreviewPainter extends CustomPainter {
  const _MapPreviewPainter(this.colorScheme);

  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE8EDE6),
    );
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(-30, size.height * 0.24)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.36,
        size.width * 0.54,
        size.height * 0.12,
        size.width + 20,
        size.height * 0.32,
      );
    canvas.drawPath(path, roadPaint);
    final crossRoad = Path()
      ..moveTo(size.width * 0.32, -20)
      ..cubicTo(
        size.width * 0.4,
        size.height * 0.34,
        size.width * 0.2,
        size.height * 0.58,
        size.width * 0.43,
        size.height + 20,
      );
    canvas.drawPath(crossRoad, roadPaint);
    final parkPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.62, size.height * 0.48, 120, 90),
        const Radius.circular(22),
      ),
      parkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MapPreviewPainter oldDelegate) =>
      colorScheme != oldDelegate.colorScheme;
}
