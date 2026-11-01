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

      if (mounted) {
        setState(() => _busy = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        _showError(error);
      }
    }
  }

  Future<void> _checkout() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutPage(api: widget.api),
      ),
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          AppStrings.shoppingBagTitle,
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        actions: [
          if (cart != null && cart.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Center(
                child: Text(
                  '${cart.items.length} ITEMS',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const SkeletonRowList()
          : _error != null
              ? ErrorStateView(message: _error!)
              : cart!.items.isEmpty
                  ? _buildEmptyBag()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        18,
                        12,
                        18,
                        28,
                      ),
                      children: [
                        const Text(
                          'YOUR SELECTION',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final item in cart.items) ...[
                          _CartLine(
                            item: item,
                            busy: _busy,
                            onChange: (quantity) =>
                                _changeQuantity(item, quantity),
                          ),
                          const SizedBox(height: 14),
                        ],
                        const SizedBox(height: 12),
                        _SummaryCard(cart: cart),
                      ],
                    ),
      bottomNavigationBar: cart == null || cart.items.isEmpty
          ? null
          : _buildCheckoutBar(cart),
    );
  }

  Widget _buildEmptyBag() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F3F3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 42,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'YOUR BAG IS EMPTY',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.bagEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text(
                'CONTINUE SHOPPING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBar(Cart cart) {
    const shipping = 0.0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5E5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formatPrice(
                        cart.subtotal + shipping,
                        cart.currencyCode,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _busy ? null : _checkout,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.black26,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.checkoutTitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 17),
                      ],
                    ),
                  ),
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: item.imageUrl == null
                ? _imagePlaceholder()
                : Image.network(
                    item.imageUrl!,
                    width: 96,
                    height: 116,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy:
                        WebHtmlElementStrategy.fallback,
                    errorBuilder: (_, _, _) => _imagePlaceholder(),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  AppStrings.variantSummary(item.size, item.color),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  formatPrice(item.lineTotal, item.currencyCode),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StepperButton(
                      icon: Icons.remove,
                      onPressed: busy
                          ? null
                          : () => onChange(item.quantity - 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StepperButton(
                      icon: Icons.add,
                      onPressed:
                          busy || item.quantity >= item.stockQuantity
                              ? null
                              : () => onChange(item.quantity + 1),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: AppStrings.tooltipRemoveItem,
                      onPressed: busy ? null : () => onChange(0),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.black54,
                        size: 21,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 96,
      height: 116,
      color: const Color(0xFFF1F1F1),
      child: const Center(
        child: Icon(
          Icons.checkroom_outlined,
          size: 34,
          color: Colors.black38,
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: onPressed == null
              ? const Color(0xFFF5F5F5)
              : Colors.white,
          border: Border.all(
            color: onPressed == null
                ? const Color(0xFFE5E5E5)
                : Colors.black,
          ),
        ),
        child: Icon(
          icon,
          size: 15,
          color: onPressed == null ? Colors.black26 : Colors.black,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    const shipping = 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORDER SUMMARY',
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 18),
          _SummaryRow(
            label: AppStrings.subtotal,
            value: formatPrice(cart.subtotal, cart.currencyCode),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: AppStrings.delivery,
            value: formatPrice(shipping, cart.currencyCode),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFDDDDDD), height: 1),
          ),
          _SummaryRow(
            label: AppStrings.total,
            value: formatPrice(
              cart.subtotal + shipping,
              cart.currencyCode,
            ),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized ? Colors.black : Colors.black54,
              fontSize: emphasized ? 13 : 12,
              fontWeight: emphasized ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.black,
            fontSize: emphasized ? 15 : 12,
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}