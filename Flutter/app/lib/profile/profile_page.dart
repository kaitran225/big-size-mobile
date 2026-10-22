import 'package:flutter/material.dart';

import '../addresses/addresses_page.dart';
import '../assistant/assistant_page.dart';
import '../auth/auth_page.dart';
import '../admin/store_management_page.dart';
import '../favorites/favorites_page.dart';
import '../models/store_product.dart';
import '../notifications/notifications_page.dart';
import '../orders/orders_page.dart';
import '../security/security_page.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/theme/app_theme.dart';
import '../staff/shipment_board_page.dart';

/// Dedicated account page: identity, activity counters and every account
/// destination in one place.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.api, this.onSessionChanged});

  final StoreApi api;
  final ValueChanged<AuthSession?>? onSessionChanged;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AuthSession? _session;
  int _orderCount = 0;
  int _favoriteCount = 0;
  int _addressCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final session = await widget.api.loadSession();
      var orders = 0;
      var favorites = 0;
      var addresses = 0;
      if (session != null) {
        orders = (await widget.api.getOrders()).length;
        favorites = (await widget.api.getFavorites()).length;
        addresses = (await widget.api.getAddresses()).length;
      }
      if (!mounted) return;
      setState(() {
        _session = session;
        _orderCount = orders;
        _favoriteCount = favorites;
        _addressCount = addresses;
        _loading = false;
      });
      widget.onSessionChanged?.call(session);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool get _isStaff => (_session?.roles ?? const <String>[]).any((role) {
    final normalized = role.toLowerCase();
    return normalized.contains('admin') || normalized.contains('staff');
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = _session;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.accountTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                _buildIdentityCard(theme, session),
                const SizedBox(height: AppSpacing.lg),
                _buildStats(theme),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  AppStrings.accountOverview,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildMenu(theme),
                const SizedBox(height: AppSpacing.xl),
                if (session != null)
                  OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text(AppStrings.signOutAction),
                  )
                else
                  FilledButton.icon(
                    onPressed: _openAuth,
                    icon: const Icon(Icons.login),
                    label: const Text(AppStrings.signIn),
                  ),
              ],
            ),
    );
  }

  Widget _buildIdentityCard(ThemeData theme, AuthSession? session) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.brandSoft,
            child: Text(
              session == null || session.displayName.isEmpty
                  ? AppStrings.avatarFallback
                  : session.displayName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.brand,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session?.displayName ?? AppStrings.guest,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  session?.email ?? AppStrings.signInToSaveProfile,
                  style: theme.textTheme.bodySmall,
                ),
                if (session != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      AppStrings.roleLabel(session.roles.join(', ')),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildStats(ThemeData theme) => Row(
    children: [
      Expanded(
        child: _StatTile(
          value: '$_orderCount',
          label: AppStrings.accountOrders,
          icon: Icons.receipt_long_outlined,
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: _StatTile(
          value: '$_favoriteCount',
          label: AppStrings.accountFavorites,
          icon: Icons.favorite_border,
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: _StatTile(
          value: '$_addressCount',
          label: AppStrings.accountAddresses,
          icon: Icons.location_on_outlined,
        ),
      ),
    ],
  );

  Widget _buildMenu(ThemeData theme) => Card(
    child: Column(
      children: [
        _MenuRow(
          icon: Icons.receipt_long_outlined,
          label: AppStrings.accountOrders,
          onTap: () => _open(OrdersPage(api: widget.api)),
        ),
        const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
        _MenuRow(
          icon: Icons.location_on_outlined,
          label: AppStrings.accountAddresses,
          onTap: () => _open(AddressesPage(api: widget.api)),
        ),
        const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
        _MenuRow(
          icon: Icons.favorite_border,
          label: AppStrings.accountFavorites,
          onTap: () => _open(FavoritesPage(api: widget.api)),
        ),
        const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
        _MenuRow(
          icon: Icons.notifications_outlined,
          label: AppStrings.accountNotifications,
          onTap: () => _open(NotificationsPage(api: widget.api)),
        ),
        const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
        _MenuRow(
          icon: Icons.auto_awesome_outlined,
          label: AppStrings.accountStylist,
          onTap: () => _open(AssistantPage(api: widget.api, gender: 'Women')),
        ),
        const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
        _MenuRow(
          icon: Icons.security_outlined,
          label: AppStrings.accountSecurity,
          onTap: () => _open(const SecurityPage()),
        ),
        const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
        if (_isStaff) ...[
          const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
          _MenuRow(
            icon: Icons.storefront_outlined,
            label: AppStrings.storeManagementTitle,
            onTap: () =>
                _open(StoreManagementPage(roles: _session?.roles ?? const [])),
          ),
          const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
          _MenuRow(
            icon: Icons.local_shipping_outlined,
            label: AppStrings.staffShipmentsTitle,
            onTap: () => _open(ShipmentBoardPage(api: widget.api)),
          ),
        ],
      ],
    ),
  );

  Future<void> _open(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    await _load();
  }

  Future<void> _signOut() async {
    await widget.api.signOut();
    if (!mounted) return;
    setState(() {
      _session = null;
      _orderCount = 0;
      _favoriteCount = 0;
      _addressCount = 0;
    });
    widget.onSessionChanged?.call(null);
  }

  Future<void> _openAuth() async {
    final session = await Navigator.of(context).push<AuthSession>(
      MaterialPageRoute<AuthSession>(builder: (_) => AuthPage(api: widget.api)),
    );
    if (session != null) await _load();
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.lg,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: AppColors.hairline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.brand),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.inkMuted),
        ),
      ],
    ),
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.ink),
    title: Text(label),
    trailing: const Icon(Icons.chevron_right, color: AppColors.inkMuted),
    onTap: onTap,
  );
}
