import 'package:flutter/material.dart';

import '../admin/admin_products_page.dart';
import '../admin/admin_users_page.dart';
import '../models/store_product.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/app_info_note.dart';
import '../shared/widgets/app_list_tile_card.dart';
import '../shared/widgets/app_section_header.dart';
import 'shipment_board_page.dart';

/// Landing screen for StoreStaff and Admin accounts: work first, shopping second.
class StaffWorkspacePage extends StatelessWidget {
  const StaffWorkspacePage({
    super.key,
    required this.api,
    required this.session,
    required this.onShopAsCustomer,
    required this.onSignOut,
  });

  final StoreApi api;
  final AuthSession session;
  final VoidCallback onShopAsCustomer;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = session.isAdmin ? 'Admin' : 'Store staff';
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.staffWorkspaceTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.signOut,
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.displayName,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.staffWorkspaceGreeting(session.email, role),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(text: AppStrings.workspaceFulfilmentSection),
          const SizedBox(height: 12),
          AppListTileCard(
            icon: Icons.local_shipping_outlined,
            title: AppStrings.ordersQueue,
            subtitle: AppStrings.ordersQueueDetail,
            onTap: () => _open(context, ShipmentBoardPage(api: api)),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(text: AppStrings.workspaceManagementSection),
          const SizedBox(height: 12),
          AppListTileCard(
            icon: Icons.inventory_2_outlined,
            title: AppStrings.inventoryTitle,
            subtitle: AppStrings.productsAndInventoryDetail,
            onTap: () => _open(context, AdminProductsPage(api: api)),
          ),
          if (session.isAdmin)
            AppListTileCard(
              icon: Icons.group_outlined,
              title: AppStrings.usersAndRoles,
              subtitle: AppStrings.usersAndRolesDetail,
              onTap: () => _open(context, AdminUsersPage(api: api)),
            ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(text: AppStrings.workspaceStorefrontSection),
          const SizedBox(height: 12),
          AppListTileCard(
            icon: Icons.storefront_outlined,
            title: AppStrings.shopAsCustomer,
            subtitle: AppStrings.shopAsCustomerDetail,
            onTap: onShopAsCustomer,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppInfoNote(
            text: AppStrings.storeManagementRestricted,
            style: AppInfoNoteStyle.plain,
          ),
        ],
      ),
    );
  }

  static void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
