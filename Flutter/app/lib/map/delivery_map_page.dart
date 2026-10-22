import 'package:flutter/material.dart';

import '../shared/app_strings.dart';

class DeliveryMapPage extends StatefulWidget {
  const DeliveryMapPage({super.key});

  @override
  State<DeliveryMapPage> createState() => _DeliveryMapPageState();
}

class _DeliveryMapPageState extends State<DeliveryMapPage> {
  final _searchController = TextEditingController();
  String _selectedLocation = AppStrings.demoLocation;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.mapTitle)),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(
              () => _selectedLocation = value.trim().isEmpty
                  ? AppStrings.demoLocation
                  : value.trim(),
            ),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: AppStrings.mapSearchHint,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              const Positioned.fill(child: _MapPreview()),
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 38),
                  child: Icon(
                    Icons.location_on,
                    color: Color(0xFF174C3C),
                    size: 46,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppStrings.mapPreviewNotice,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.selectedLocation,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedLocation,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(AppStrings.useThisLocation),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MapPreview extends StatelessWidget {
  const _MapPreview();

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
