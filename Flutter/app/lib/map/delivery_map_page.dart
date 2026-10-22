import 'package:flutter/material.dart';

import '../shared/app_strings.dart';
import '../shared/theme/app_theme.dart';
import 'map_point_picker.dart';

/// Full screen map picker that returns the coordinates of a chosen point.
class DeliveryMapPage extends StatefulWidget {
  const DeliveryMapPage({super.key});

  @override
  State<DeliveryMapPage> createState() => _DeliveryMapPageState();
}

class _DeliveryMapPageState extends State<DeliveryMapPage> {
  double? _latitude;
  double? _longitude;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPoint = _latitude != null && _longitude != null;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.mapTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Text(AppStrings.dropPinHint, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          MapPointPicker(
            height: 360,
            onPointChanged: (latitude, longitude) => setState(() {
              _latitude = latitude;
              _longitude = longitude;
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.brand,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasPoint
                              ? AppStrings.pinPlaced
                              : AppStrings.selectSizeFirst,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          hasPoint
                              ? '${_latitude!.toStringAsFixed(5)}, '
                                    '${_longitude!.toStringAsFixed(5)}'
                              : AppStrings.dropPinHint,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasPoint
                  ? () => Navigator.of(context).pop<Map<String, double>>({
                      'latitude': _latitude!,
                      'longitude': _longitude!,
                    })
                  : null,
              icon: const Icon(Icons.check),
              label: const Text(AppStrings.useThisLocation),
            ),
          ),
        ],
      ),
    );
  }
}
