import 'package:flutter/material.dart';

import '../models/checkout_models.dart';
import '../orders/order_tracker.dart';
import '../services/shipment_board.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/theme/app_theme.dart';

/// Staff view of every shipment leaving the warehouse.
class ShipmentBoardPage extends StatefulWidget {
  const ShipmentBoardPage({super.key, required this.api});

  final StoreApi api;

  @override
  State<ShipmentBoardPage> createState() => _ShipmentBoardPageState();
}

class _ShipmentBoardPageState extends State<ShipmentBoardPage> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await widget.api.loadSession();
      final orders = await widget.api.getOrders();
      for (final order in orders) {
        ShipmentBoard.instance.track(
          order,
          customerName: session?.displayName ?? AppStrings.customerLabel,
        );
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is StoreApiException
            ? error.message
            : AppStrings.errorLoadBag;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shipments = ShipmentBoard.instance.shipments;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.staffShipmentsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : shipments.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  AppStrings.noShipments,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              itemCount: shipments.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            AppStrings.boardNote,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return _ShipmentCard(
                  shipment: shipments[index - 1],
                  onAdvance: () => setState(() {
                    ShipmentBoard.instance.advance(shipments[index - 1]);
                  }),
                );
              },
            ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({required this.shipment, required this.onAdvance});

  final Shipment shipment;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    shipment.orderNumber,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: shipment.isDelivered
                        ? AppColors.brandSoft
                        : AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    ShipmentTracker.stageLabel(shipment.stage),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: shipment.isDelivered
                          ? AppColors.brand
                          : AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${AppStrings.customerLabel}: ${shipment.customerName}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '${AppStrings.courier}: ${shipment.courier} · '
              '${shipment.trackingNumber}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            ShipmentTracker(stage: shipment.stage),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: shipment.isDelivered ? null : onAdvance,
                icon: const Icon(Icons.trending_up),
                label: Text(
                  shipment.isDelivered
                      ? AppStrings.stageDelivered
                      : AppStrings.advanceStatus,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
