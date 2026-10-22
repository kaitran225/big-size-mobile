import 'package:flutter/material.dart';

import '../models/store_product.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';
import '../shared/widgets/async_content_view.dart';

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
      emptyMessage: AppStrings.ordersEmpty,
      builder: (context, orders) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            child: ExpansionTile(
              title: Text(order.orderNumber),
              subtitle: Text(
                AppStrings.orderStatusLine(
                  order.status,
                  formatDate(order.createdAt),
                ),
              ),
              trailing: Text(
                formatPrice(order.totalAmount, order.currencyCode),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              children: order.items
                  .map(
                    (item) => ListTile(
                      title: Text(item.productName),
                      subtitle: Text(
                        AppStrings.orderItemSummary(
                          item.size,
                          item.color,
                          item.quantity,
                        ),
                      ),
                      trailing: Text(
                        formatPrice(item.lineTotal, order.currencyCode),
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    ),
  );
}
