import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../shared/app_strings.dart';
import '../shared/theme/app_theme.dart';

class MapPointPicker extends StatefulWidget {
  const MapPointPicker({
    super.key,
    required this.onPointChanged,
    this.initialLatitude,
    this.initialLongitude,
    this.height = 280,
    this.autoLocateOnStart = true,
  });

  final void Function(double latitude, double longitude) onPointChanged;
  final double? initialLatitude;
  final double? initialLongitude;
  final double height;
  final bool autoLocateOnStart;

  @override
  State<MapPointPicker> createState() => _MapPointPickerState();
}

class _MapPointPickerState extends State<MapPointPicker> {
  late MapController _mapController;
  late LatLng _currentCenter;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Vị trí mặc định: TP. Hồ Chí Minh
    _currentCenter = LatLng(
      widget.initialLatitude ?? 10.7769,
      widget.initialLongitude ?? 106.7009,
    );

    if (widget.initialLatitude == null &&
        widget.initialLongitude == null &&
        widget.autoLocateOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _locateMe());
    }
  }

  Future<void> _locateMe() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        final newCenter = LatLng(position.latitude, position.longitude);
        if (mounted) {
          setState(() {
            _currentCenter = newCenter;
            _isLocating = false;
          });
          _mapController.move(newCenter, 16.0);
          widget.onPointChanged(newCenter.latitude, newCenter.longitude);
        }
        return;
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }

    if (mounted) {
      setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentCenter,
                initialZoom: 15.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _currentCenter = point;
                  });
                  widget.onPointChanged(point.latitude, point.longitude);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                  maxZoom: 19,
                  maxNativeZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentCenter,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 6),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Nút "Vị trí của tôi" (Locate Me Button)
            Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: FloatingActionButton.small(
                heroTag: null,
                onPressed: _isLocating ? null : _locateMe,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.brand,
                tooltip: AppStrings.myLocationTooltip,
                child: _isLocating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.brand,
                        ),
                      )
                    : const Icon(Icons.my_location),
              ),
            ),
            // Hiển thị tọa độ ở góc dưới bên trái
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
                  '${_currentCenter.latitude.toStringAsFixed(5)}, ${_currentCenter.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}