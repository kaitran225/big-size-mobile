import 'package:flutter/material.dart';

import '../shared/app_strings.dart';
import 'map_preview.dart';

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
              const Positioned.fill(child: MapPreview()),
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
