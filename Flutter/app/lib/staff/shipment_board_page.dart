import 'package:flutter/material.dart';

import '../models/checkout_models.dart';
import '../orders/order_tracker.dart';
import '../services/order_shipment_mapper.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/app_snack_bar.dart';

/// Staff view of every order in the fulfilment queue.
class ShipmentBoardPage extends StatefulWidget {
  const ShipmentBoardPage({super.key, required this.api});

  final StoreApi api;

  @override
  State<ShipmentBoardPage> createState() => _ShipmentBoardPageState();
}

class _ShipmentBoardPageState extends State<ShipmentBoardPage> {
  bool _loading = true;
  String? _error;
  List<StaffFulfillmentOrder> _orders = const [];
  bool _includeDelivered = false;

  @override
  void initState() {
    super.initState();
    _load();
    widget.api.realtime.staffQueueTick.addListener(_onStaffEvent);
  }

  @override
  void dispose() {
    widget.api.realtime.staffQueueTick.removeListener(_onStaffEvent);
    super.dispose();
  }

  void _onStaffEvent() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await widget.api.getFulfillmentOrders(
        includeDelivered: _includeDelivered,
      );
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
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

  Future<void> _advance(StaffFulfillmentOrder order) async {
    final action = OrderShipmentMapper.nextFulfillmentAction(order.status);
    if (action == null) return;
    try {
      await widget.api.applyFulfillmentAction(
        orderId: order.id,
        action: action,
      );
      if (mounted) await _load();
    } catch (error) {
      if (!mounted) return;
      showAppErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.staffShipmentsTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.refresh,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _orders.isEmpty
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
              itemCount: _orders.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(AppStrings.showDeliveredOrders),
                        value: _includeDelivered,
                        onChanged: (value) {
                          setState(() => _includeDelivered = value);
                          _load();
                        },
                      ),
                      Container(
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
                      ),
                    ],
                  );
                }
                return _ShipmentCard(
                  order: _orders[index - 1],
                  onAdvance: () => _advance(_orders[index - 1]),
                );
              },
            ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({required this.order, required this.onAdvance});

  final StaffFulfillmentOrder order;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stage = OrderShipmentMapper.stageForStatus(order.status);
    final action = OrderShipmentMapper.nextFulfillmentAction(order.status);
    final isPendingBankTransfer =
        order.status == 'Pending' &&
        order.paymentMethod == 'bankTransfer' &&
        order.paymentStatus == 'Pending';
    final actionLabel = isPendingBankTransfer
        ? AppStrings.fulfillmentVerifyAndAccept
        : switch (action) {
            'accept' => AppStrings.fulfillmentAccept,
            'ship' => AppStrings.fulfillmentShip,
            'complete' => AppStrings.fulfillmentComplete,
            _ => AppStrings.advanceStatus,
          };
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
                    order.orderNumber,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: order.isDelivered
                        ? AppColors.brandSoft
                        : AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    AppStrings.orderStatus(order.status),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: order.isDelivered
                          ? AppColors.brand
                          : AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${AppStrings.customerLabel}: ${order.customerName}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              formatPrice(order.totalAmount, order.currencyCode),
              style: theme.textTheme.bodySmall,
            ),
            if (order.paymentMethod != null)
              Text(
                '${AppStrings.paymentTitle}: ${order.paymentMethod} · ${order.paymentStatus ?? ""}',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: AppSpacing.lg),
            ShipmentTracker(stage: stage),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: action == null ? null : onAdvance,
                icon: const Icon(Icons.trending_up),
                label: Text(
                  order.isDelivered ? AppStrings.stageDelivered : actionLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
