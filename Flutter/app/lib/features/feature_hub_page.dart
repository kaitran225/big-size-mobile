import 'package:flutter/material.dart';

import '../admin/store_management_page.dart';
import '../map/delivery_map_page.dart';
import '../models/store_product.dart';
import '../payment/payment_page.dart';
import '../profile/profile_page.dart';
import '../security/security_page.dart';
import '../shared/app_strings.dart';

class FeatureHubPage extends StatelessWidget {
  const FeatureHubPage({super.key, required this.session});

  final AuthSession? session;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.featureHubTitle)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          AppStrings.yourAccount,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        _FeatureTile(
          icon: Icons.person_outline,
          title: AppStrings.profileAndFit,
          subtitle: session == null
              ? AppStrings.profileAndFitPreview
              : AppStrings.profileAndFitSignedIn,
          onTap: () => _open(context, ProfilePage(session: session)),
        ),
        _FeatureTile(
          icon: Icons.map_outlined,
          title: AppStrings.deliveryMap,
          subtitle: AppStrings.chooseDeliveryLocation,
          onTap: () => _open(context, const DeliveryMapPage()),
        ),
        _FeatureTile(
          icon: Icons.payments_outlined,
          title: AppStrings.paymentMethods,
          subtitle: AppStrings.paymentMethodsSubtitle,
          onTap: () => _open(context, const PaymentPage()),
        ),
        _FeatureTile(
          icon: Icons.security_outlined,
          title: AppStrings.accountSecurity,
          subtitle: AppStrings.accountSecuritySubtitle,
          onTap: () => _open(context, const SecurityPage()),
        ),
        if (_isStaffOrAdmin(session?.roles ?? const [])) ...[
          const SizedBox(height: 20),
          Text(
            AppStrings.storeTools,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          _FeatureTile(
            icon: Icons.store_mall_directory_outlined,
            title: AppStrings.storeManagementTitle,
            subtitle: AppStrings.storeToolsSubtitle,
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
