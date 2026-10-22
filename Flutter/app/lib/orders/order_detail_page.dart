import 'package:flutter/material.dart';

import '../models/checkout_models.dart';
import '../models/store_product.dart';
import '../services/shipment_board.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';
import '../shared/theme/app_theme.dart';
import 'order_tracker.dart';

/// Order page with the shipment tracker for one placed order.
class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.api, required this.order});

  final StoreApi api;
  final CustomerOrder order;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Shipment _shipment;

  @override
  void initState() {
    super.initState();
    _shipment = ShipmentBoard.instance.track(widget.order);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;
    return Scaffold(
      appBar: AppBar(title: Text(order.orderNumber)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.orderPlacedOn,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        formatDate(order.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.orderStatusTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      _StatusChip(label: order.status),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(AppStrings.shipmentTracking, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetaLine(
                          label: AppStrings.trackingNumber,
                          value: _shipment.trackingNumber,
                        ),
                      ),
                      Expanded(
                        child: _MetaLine(
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
          Text(AppStrings.orderItems, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  for (final item in order.items) ...[
                    _OrderLine(item: item, currencyCode: order.currencyCode),
                    const Divider(height: AppSpacing.lg),
                  ],
                  _TotalRow(
                    label: AppStrings.subtotal,
                    value: formatPrice(order.subtotal, order.currencyCode),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _TotalRow(
                    label: AppStrings.delivery,
                    value: order.shippingAmount == 0
                        ? AppStrings.free
                        : formatPrice(order.shippingAmount, order.currencyCode),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _TotalRow(
                    label: AppStrings.total,
                    value: formatPrice(order.totalAmount, order.currencyCode),
                    emphasise: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.brandSoft,
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.brand,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

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

class _OrderLine extends StatelessWidget {
  const _OrderLine({required this.item, required this.currencyCode});

  final OrderItem item;
  final String currencyCode;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 44,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9E1),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: const Icon(Icons.checkroom_outlined, color: Colors.black38),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              AppStrings.orderItemSummary(item.size, item.color, item.quantity),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      Text(formatPrice(item.lineTotal, currencyCode)),
    ],
  );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final style = emphasise
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
