import 'package:flutter/material.dart';

import '../shared/app_strings.dart';

class StoreManagementPage extends StatelessWidget {
  const StoreManagementPage({super.key, required this.roles});

  final List<String> roles;

  @override
  Widget build(BuildContext context) {
    final canManage = roles.any((role) {
      final normalized = role.toLowerCase();
      return normalized.contains('admin') || normalized.contains('staff');
    });

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.storeManagementTitle)),
      body: canManage
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  AppStrings.managementOverview,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const _ManagementCard(
                  icon: Icons.inventory_2_outlined,
                  title: AppStrings.productsAndInventory,
                  detail: AppStrings.productsAndInventoryDetail,
                ),
                const _ManagementCard(
                  icon: Icons.receipt_long_outlined,
                  title: AppStrings.ordersTitle,
                  detail: AppStrings.ordersDetail,
                ),
                const _ManagementCard(
                  icon: Icons.rate_review_outlined,
                  title: AppStrings.customerReviews,
                  detail: AppStrings.customerReviewsDetail,
                ),
                const SizedBox(height: 12),
                const Text(
                  AppStrings.managementNotConnected,
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  AppStrings.storeManagementRestricted,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(detail),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}
