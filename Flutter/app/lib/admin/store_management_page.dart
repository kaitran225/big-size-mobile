import 'package:flutter/material.dart';

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
      appBar: AppBar(title: const Text('Store management')),
      body: canManage
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Management overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const _ManagementCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Products & inventory',
                  detail: 'Manage catalogue items, variants, and stock.',
                ),
                const _ManagementCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Orders',
                  detail: 'Review orders and update fulfilment status.',
                ),
                const _ManagementCard(
                  icon: Icons.rate_review_outlined,
                  title: 'Customer reviews',
                  detail: 'Moderate product feedback.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Management endpoints are not connected. This screen does not change store data.',
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Store management is available to Admin and Store Staff accounts.',
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
