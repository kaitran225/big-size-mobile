import 'package:flutter/material.dart';

import '../shared/app_strings.dart';
import '../shared/widgets/app_info_note.dart';
import '../shared/widgets/app_list_tile_card.dart';
import '../shared/widgets/app_section_header.dart';
import 'admin_orders_page.dart';
import 'admin_products_page.dart';
import 'admin_reviews_page.dart';

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
                const AppSectionHeader(text: AppStrings.managementOverview),
                const SizedBox(height: 12),
                AppListTileCard(
                  icon: Icons.inventory_2_outlined,
                  title: AppStrings.productsAndInventory,
                  subtitle: AppStrings.productsAndInventoryDetail,
                  onTap: () => _open(context, const AdminProductsPage()),
                ),
                AppListTileCard(
                  icon: Icons.receipt_long_outlined,
                  title: AppStrings.ordersTitle,
                  subtitle: AppStrings.ordersDetail,
                  onTap: () => _open(context, const AdminOrdersPage()),
                ),
                AppListTileCard(
                  icon: Icons.rate_review_outlined,
                  title: AppStrings.customerReviews,
                  subtitle: AppStrings.customerReviewsDetail,
                  onTap: () => _open(context, const AdminReviewsPage()),
                ),
                const SizedBox(height: 12),
                const AppInfoNote(
                  text: AppStrings.managementNotConnected,
                  style: AppInfoNoteStyle.plain,
                ),
              ],
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: AppInfoNote(
                  text: AppStrings.storeManagementRestricted,
                  style: AppInfoNoteStyle.plain,
                ),
              ),
            ),
    );
  }

  static void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
