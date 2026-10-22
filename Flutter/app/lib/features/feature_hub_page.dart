import 'package:flutter/material.dart';

import '../admin/store_management_page.dart';
import '../map/delivery_map_page.dart';
import '../models/store_product.dart';
import '../payment/payment_page.dart';
import '../profile/profile_page.dart';
import '../security/security_page.dart';

class FeatureHubPage extends StatelessWidget {
  const FeatureHubPage({super.key, required this.session});

  final AuthSession? session;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('More from BigFit')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Your account', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        _FeatureTile(
          icon: Icons.person_outline,
          title: 'Profile & fit preferences',
          subtitle: session == null
              ? 'Preview account details and fit preferences'
              : 'Personal details, sizes, and reviews',
          onTap: () => _open(context, ProfilePage(session: session)),
        ),
        _FeatureTile(
          icon: Icons.map_outlined,
          title: 'Delivery map',
          subtitle: 'Choose a delivery location',
          onTap: () => _open(context, const DeliveryMapPage()),
        ),
        _FeatureTile(
          icon: Icons.payments_outlined,
          title: 'Payment methods',
          subtitle: 'COD, bank transfer, and gateway preview',
          onTap: () => _open(context, const PaymentPage()),
        ),
        _FeatureTile(
          icon: Icons.security_outlined,
          title: 'Account security',
          subtitle: 'Email verification, reset, and OTP',
          onTap: () => _open(context, const SecurityPage()),
        ),
        if (_isStaffOrAdmin(session?.roles ?? const [])) ...[
          const SizedBox(height: 20),
          Text('Store tools', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          _FeatureTile(
            icon: Icons.store_mall_directory_outlined,
            title: 'Store management',
            subtitle: 'Products, inventory, orders, and reviews',
            onTap: () => _open(
              context,
              StoreManagementPage(roles: session?.roles ?? const []),
            ),
          ),
        ],
      ],
    ),
  );

  static bool _isStaffOrAdmin(List<String> roles) => roles.any((role) {
    final normalized = role.toLowerCase();
    return normalized.contains('admin') || normalized.contains('staff');
  });

  static Future<void> _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
