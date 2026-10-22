import 'package:flutter/material.dart';

import '../models/store_product.dart';
import '../orders/order_detail_page.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/async_content_view.dart';

/// Order history with a summary card per order and a link to the tracker.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, required this.api});

  final StoreApi api;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<CustomerOrder>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = widget.api.getOrders();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.orderHistoryTitle)),
    body: AsyncContentView<List<CustomerOrder>>(
      future: _orders,
      isEmpty: (items) => items.isEmpty,
      emptyMessage: AppStrings.noOrdersTitle,
      emptyIcon: Icons.receipt_long_outlined,
      builder: (context, orders) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OrderDetailPage(api: widget.api, order: order),
                ),
              ),
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
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          formatPrice(order.totalAmount, order.currencyCode),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.orderStatusLine(
                        order.status,
                        formatDate(order.createdAt),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final item in order.items.take(3))
                          _ItemChip(item: item),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Text(
                          AppStrings.trackOrder,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.brand,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppColors.brand,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _ItemChip extends StatelessWidget {
  const _ItemChip({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      border: Border.all(color: AppColors.hairline),
    ),
    child: Text(
      '${item.productName} · ${item.size} × ${item.quantity}',
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}
