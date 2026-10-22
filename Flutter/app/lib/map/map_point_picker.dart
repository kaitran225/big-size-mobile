import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../shared/theme/app_theme.dart';

/// A tappable delivery map that turns a tap into map coordinates.
///
/// The production build swaps this for `google_maps_flutter`, so the widget
/// keeps the same contract: the caller receives a latitude and longitude and
/// can move the pin until it sits on the right spot.
class MapPointPicker extends StatefulWidget {
  const MapPointPicker({
    super.key,
    required this.onPointChanged,
    this.initialLatitude,
    this.initialLongitude,
    this.height = 280,
  });

  final void Function(double latitude, double longitude) onPointChanged;
  final double? initialLatitude;
  final double? initialLongitude;
  final double height;

  @override
  State<MapPointPicker> createState() => _MapPointPickerState();
}

class _MapPointPickerState extends State<MapPointPicker> {
  static const double _minLatitude = 10.70;
  static const double _maxLatitude = 10.82;
  static const double _minLongitude = 106.60;
  static const double _maxLongitude = 106.80;

  Offset? _pin;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    final latitude = widget.initialLatitude;
    final longitude = widget.initialLongitude;
    if (latitude != null && longitude != null) {
      _latitude = latitude;
      _longitude = longitude;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, widget.height);
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => _updatePin(details.localPosition, size),
          onPanUpdate: (details) => _updatePin(details.localPosition, size),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _DeliveryMapPainter(pin: _pin),
                ),
              ),
              if (_pin != null)
                Positioned(
                  left: _pin!.dx - 22,
                  top: _pin!.dy - 46,
                  child: const _PinMarker(),
                ),
              Positioned(
                left: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Text(
                    _latitude == null
                        ? 'Tap to place a pin'
                        : '${_latitude!.toStringAsFixed(5)}, '
                              '${_longitude!.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  void _updatePin(Offset position, Size size) {
    final dx = position.dx.clamp(0.0, size.width);
    final dy = position.dy.clamp(0.0, size.height);
    final latitude =
        _maxLatitude - (dy / size.height) * (_maxLatitude - _minLatitude);
    final longitude =
        _minLongitude + (dx / size.width) * (_maxLongitude - _minLongitude);
    setState(() {
      _pin = Offset(dx, dy);
      _latitude = latitude;
      _longitude = longitude;
    });
    widget.onPointChanged(latitude, longitude);
  }
}

class _PinMarker extends StatelessWidget {
  const _PinMarker();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: AppColors.brand,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.location_on,
          color: Colors.white,
          size: 20,
        ),
      ),
      Container(width: 2, height: 12, color: AppColors.brand),
    ],
  );
}

/// Paints a stylised street map so the picker reads as a map surface.
class _DeliveryMapPainter extends CustomPainter {
  _DeliveryMapPainter({this.pin});

  final Offset? pin;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFEFE9DE);
    canvas.drawRect(Offset.zero & size, background);

    final park = Paint()..color = const Color(0xFFD9E6D3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.06,
          size.height * 0.08,
          size.width * 0.3,
          size.height * 0.24,
        ),
        const Radius.circular(18),
      ),
      park,
    );

    final water = Paint()..color = const Color(0xFFD5E4EC);
    final river = Path()
      ..moveTo(size.width * 0.72, 0)
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.3,
        size.width * 0.9,
        size.height * 0.6,
        size.width * 0.78,
        size.height,
      );
    canvas.drawPath(river, water);

    final block = Paint()..color = const Color(0xFFE4DCD0);
    final random = math.Random(7);
    for (var index = 0; index < 26; index++) {
      final left = random.nextDouble() * size.width;
      final top = random.nextDouble() * size.height;
      final width = 18 + random.nextDouble() * 46;
      final height = 14 + random.nextDouble() * 34;
      if (left + width > size.width || top + height > size.height) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, width, height),
          const Radius.circular(4),
        ),
        block,
      );
    }

    final street = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final lanes = Paint()
      ..color = const Color(0xFFE6E0D4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var index = 1; index <= 3; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), street);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lanes);
    }
    for (var index = 1; index <= 4; index++) {
      final x = size.width * index / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), street);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), lanes);
    }

    if (pin != null) {
      final halo = Paint()..color = AppColors.brand.withValues(alpha: 0.12);
      canvas.drawCircle(pin!, 34, halo);
    }
  }

  @override
  bool shouldRepaint(_DeliveryMapPainter oldDelegate) => oldDelegate.pin != pin;
}
