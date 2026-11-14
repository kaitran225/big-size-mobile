import 'package:flutter/material.dart';

import '../models/checkout_models.dart';
import '../models/store_product.dart';
import '../services/order_shipment_mapper.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';
import '../shared/theme/app_theme.dart';
import 'delivery_tracking_map.dart';
import 'order_tracker.dart';

/// Full-page shipment tracker for one order, drawn on the order's own map point.
class ShipmentTrackerPage extends StatefulWidget {
  const ShipmentTrackerPage({super.key, required this.api, required this.order});

  final StoreApi api;
  final CustomerOrder order;

  @override
  State<ShipmentTrackerPage> createState() => _ShipmentTrackerPageState();
}

class _ShipmentTrackerPageState extends State<ShipmentTrackerPage> {
  late CustomerOrder _order;
  late Shipment _shipment;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _shipment = OrderShipmentMapper.shipmentForOrder(_order);
    widget.api.realtime.orderStatusChanged.addListener(_onStatusChanged);
    _refresh();
  }

  @override
  void dispose() {
    widget.api.realtime.orderStatusChanged.removeListener(_onStatusChanged);
    super.dispose();
  }

  void _onStatusChanged() {
    final change = widget.api.realtime.orderStatusChanged.value;
    if (change?.orderId == _order.id) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    try {
      final latest = await widget.api.getOrder(_order.id);
      if (!mounted) return;
      setState(() {
        _order = latest;
        _shipment = OrderShipmentMapper.shipmentForOrder(latest);
      });
    } catch (_) {
      // Keep the last known stage; the next pull retries.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = _order.shippingAddress;
    final hasPoint = address?.hasCoordinates ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.shipmentTrackerTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.refresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Text(_order.orderNumber, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.orderStatusLine(
              _order.status,
              formatDate(_order.updatedAt),
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasPoint)
            DeliveryTrackingMap(
              stage: _shipment.stage,
              destinationLatitude: address!.latitude,
              destinationLongitude: address.longitude,
              height: 300,
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  AppStrings.noMapPoint,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.shipmentTracking,
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _Meta(
                          label: AppStrings.trackingNumber,
                          value: _shipment.trackingNumber,
                        ),
                      ),
                      Expanded(
                        child: _Meta(
                          label: AppStrings.courier,
                          value: _shipment.courier,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ShipmentTracker(stage: _shipment.stage),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.deliveryAddressTitle,
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  if (address == null)
                    Text(AppStrings.noSavedContact)
                  else ...[
                    if ((address.recipientName ?? '').isNotEmpty)
                      Text(
                        address.recipientName!,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    if ((address.phoneNumber ?? '').isNotEmpty)
                      Text(address.phoneNumber!),
                    const SizedBox(height: 4),
                    Text(address.formatted),
                    if (address.hasCoordinates) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${AppStrings.mapPointLabel}: '
                        '${address.latitude!.toStringAsFixed(5)}, '
                        '${address.longitude!.toStringAsFixed(5)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}
