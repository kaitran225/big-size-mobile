import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/checkout_models.dart';
import '../shared/app_strings.dart';
import '../shared/theme/app_theme.dart';

/// Minimalist high-contrast live delivery map matching BigFit design system.
class DeliveryTrackingMap extends StatefulWidget {
  const DeliveryTrackingMap({
    super.key,
    required this.stage,
    this.destinationLatitude,
    this.destinationLongitude,
    this.height = 240,
  });

  final ShipmentStage stage;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final double height;

  @override
  State<DeliveryTrackingMap> createState() => _DeliveryTrackingMapState();
}

class _DeliveryTrackingMapState extends State<DeliveryTrackingMap> {
  late LatLng _storePos;
  late LatLng _destPos;
  List<LatLng> _routePoints = [];
  bool _loadingRoute = true;

  @override
  void initState() {
    super.initState();
    _storePos = const LatLng(10.7721, 106.6983); // BigFit Store TP.HCM
    _destPos = LatLng(
      widget.destinationLatitude ?? 10.8438,
      widget.destinationLongitude ?? 106.8408,
    );
    _loadRealRoadRoute();
  }

  Future<void> _loadRealRoadRoute() async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${_storePos.longitude},${_storePos.latitude};${_destPos.longitude},${_destPos.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final coordinates =
              routes[0]['geometry']['coordinates'] as List<dynamic>;
          final points = coordinates.map((coord) {
            final list = coord as List<dynamic>;
            return LatLng(
              (list[1] as num).toDouble(),
              (list[0] as num).toDouble(),
            );
          }).toList();

          if (mounted && points.isNotEmpty) {
            setState(() {
              _routePoints = points;
              _loadingRoute = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching OSRM road route: $e');
    }

    if (mounted) {
      setState(() {
        _routePoints = [_storePos, _destPos];
        _loadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = switch (widget.stage) {
      ShipmentStage.placed => 0.1,
      ShipmentStage.confirmed => 0.25,
      ShipmentStage.packed => 0.45,
      ShipmentStage.shipped => 0.65,
      ShipmentStage.outForDelivery => 0.85,
      ShipmentStage.delivered => 1.0,
    };

    // Vị trí xe tài xế dọc theo tuyến đường thực tế
    LatLng driverPos = _storePos;
    if (_routePoints.isNotEmpty) {
      final index = ((_routePoints.length - 1) * progress).round().clamp(
        0,
        _routePoints.length - 1,
      );
      driverPos = _routePoints[index];
    }

    final centerLat = (_storePos.latitude + _destPos.latitude) / 2;
    final centerLng = (_storePos.longitude + _destPos.longitude) / 2;

    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header thanh tiến độ Grab-style
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Icon(
                        widget.stage == ShipmentStage.delivered
                            ? Icons.check_circle
                            : Icons.directions_bike,
                        color: const Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.stage == ShipmentStage.delivered
                                ? AppStrings.trackingDeliveredSuccess
                                : AppStrings.trackingDriverOnTheWay,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                          ),
                          if (_loadingRoute)
                            Text(
                              AppStrings.trackingLoadingRoute,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.inkMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.hairline,
                    color: const Color(0xFF0F172A),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),

          // Bản đồ phong cách tối giản ESRI Light Canvas (Giống MapLibre)
          SizedBox(
            height: widget.height,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(centerLat, centerLng),
                initialZoom: 12.2,
              ),
              children: [
                // OpenStreetMap Tile Layer (Hiện bản đồ chuẩn, ổn định, 100% Không API Key & Không Watermark)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),

                // Đường chỉ đường viền Trắng + Nét Đen nổi bật (Double-layer Crisp Line)
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      // Viền ngoài màu trắng (Width 8)
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 8.0,
                        color: Colors.white,
                      ),
                      // Đường nét chính màu Đen sắc nét (Width 4.5)
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4.5,
                        color: const Color(0xFF0F172A),
                      ),
                    ],
                  ),

                // Biểu tượng các điểm trên bản đồ (Minimalist Markers)
                MarkerLayer(
                  markers: [
                    // Điểm xuất phát (Cửa hàng) - Vòng tròn Trắng Đen tối giản
                    Marker(
                      point: _storePos,
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                          border: Border.all(color: const Color(0xFF0F172A), width: 4),
                        ),
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F172A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Điểm đến (Nhà khách) - Hình vuông Trắng Đen tối giản
                    Marker(
                      point: _destPos,
                      width: 32,
                      height: 32,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                          border: Border.all(color: const Color(0xFF0F172A), width: 4),
                        ),
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Xe Shipper đang di chuyển
                    if (widget.stage != ShipmentStage.delivered)
                      Marker(
                        point: driverPos,
                        width: 40,
                        height: 40,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 6),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
