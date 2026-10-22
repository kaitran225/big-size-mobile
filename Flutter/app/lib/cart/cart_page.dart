import 'package:flutter/material.dart';

import 'checkout_page.dart';
import '../models/store_product.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/app_snack_bar.dart';
import '../shared/widgets/error_state_view.dart';
import '../shared/widgets/skeleton_row_list.dart';

/// Shopping bag with line items, an order summary and the checkout entry.
class CartPage extends StatefulWidget {
  const CartPage({super.key, required this.api});

  final StoreApi api;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Cart? _cart;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cart = await widget.api.getCart();
      if (mounted) {
        setState(() {
          _cart = cart;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is StoreApiException
              ? error.message
              : AppStrings.errorLoadBag;
          _loading = false;
        });
      }
    }
  }

  Future<void> _changeQuantity(CartItem item, int quantity) async {
    setState(() => _busy = true);
    try {
      if (quantity < 1) {
        await widget.api.removeCartItem(item.id);
        _cart = await widget.api.getCart();
      } else {
        _cart = await widget.api.updateCartItem(item.id, quantity);
      }
      if (mounted) setState(() => _busy = false);
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        _showError(error);
      }
    }
  }

  Future<void> _checkout() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CheckoutPage(api: widget.api)),
    );
    await _load();
  }

  void _showError(Object error) {
    showAppErrorSnackBar(
      context,
      error,
      fallback: AppStrings.errorRequestFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = _cart;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.shoppingBagTitle)),
      body: _loading
          ? const SkeletonRowList()
          : _error != null
          ? ErrorStateView(message: _error!)
          : cart!.items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  AppStrings.bagEmpty,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                for (final item in cart.items) ...[
                  _CartLine(
                    item: item,
                    busy: _busy,
                    onChange: (quantity) => _changeQuantity(item, quantity),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.sm),
                _SummaryCard(cart: cart),
              ],
            ),
      bottomNavigationBar: cart == null || cart.items.isEmpty
          ? null
          : _buildCheckoutBar(cart),
    );
  }

  Widget _buildCheckoutBar(Cart cart) {
    const shipping = 0.0;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.total,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      formatPrice(cart.subtotal + shipping, cart.currencyCode),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _busy ? null : _checkout,
                  child: const Text(AppStrings.checkoutTitle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.item,
    required this.busy,
    required this.onChange,
  });

  final CartItem item;
  final bool busy;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: item.imageUrl == null
                ? const SizedBox(
                    width: 84,
                    height: 100,
                    child: Icon(Icons.checkroom_outlined),
                  )
                : Image.network(
                    item.imageUrl!,
                    width: 84,
                    height: 100,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    errorBuilder: (_, _, _) => const SizedBox(
                      width: 84,
                      height: 100,
                      child: Icon(Icons.checkroom_outlined),
                    ),
                  ),
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
                  AppStrings.variantSummary(item.size, item.color),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  formatPrice(item.lineTotal, item.currencyCode),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _StepperButton(
                      icon: Icons.remove,
                      onPressed: busy
                          ? null
                          : () => onChange(item.quantity - 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text('${item.quantity}'),
                    ),
                    _StepperButton(
                      icon: Icons.add,
                      onPressed: busy || item.quantity >= item.stockQuantity
                          ? null
                          : () => onChange(item.quantity + 1),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: AppStrings.tooltipRemoveItem,
                      onPressed: busy ? null : () => onChange(0),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(AppRadii.pill),
    child: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.hairline),
        color: onPressed == null ? AppColors.canvas : AppColors.surface,
      ),
      child: Icon(icon, size: 16, color: AppColors.ink),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const shipping = 0.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.orderSummary, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: Text(AppStrings.subtotal)),
                Text(formatPrice(cart.subtotal, cart.currencyCode)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: Text(AppStrings.delivery)),
                Text(formatPrice(shipping, cart.currencyCode)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.total,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  formatPrice(cart.subtotal + shipping, cart.currencyCode),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
