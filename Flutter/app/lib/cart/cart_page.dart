import 'package:flutter/material.dart';

import '../addresses/addresses_page.dart';
import '../models/store_product.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';
import '../shared/widgets/app_dialog.dart';
import '../shared/widgets/app_snack_bar.dart';
import '../shared/widgets/error_state_view.dart';
import '../shared/widgets/skeleton_row_list.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key, required this.api});

  final StoreApi api;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Cart? _cart;
  List<CustomerAddress> _addresses = [];
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
              : AppStrings.errorLoadCart;
          _loading = false;
        });
      }
    }
  }

  Future<void> _changeQuantity(CartItem item, int quantity) async {
    setState(() => _busy = true);
    try {
      if (quantity < 1) {
        _cart = await _cartAfterRemove(item.id);
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

  Future<Cart> _cartAfterRemove(String id) async {
    await widget.api.removeCartItem(id);
    return widget.api.getCart();
  }

  Future<void> _checkout() async {
    try {
      setState(() => _busy = true);
      _addresses = await widget.api.getAddresses();
      if (!mounted) return;
      if (_addresses.isEmpty) {
        setState(() => _busy = false);
        final openAddresses = await showDialog<bool>(
          context: context,
          builder: (context) => AppDialog(
            title: AppStrings.addressNeededTitle,
            content: const Text(AppStrings.addressNeededMessage),
            cancelLabel: AppStrings.later,
            confirmLabel: AppStrings.addAddress,
          ),
        );
        if (openAddresses == true && mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AddressesPage(api: widget.api),
            ),
          );
          await _checkout();
        }
        return;
      }
      var selectedId =
          _addresses.where((address) => address.isDefault).firstOrNull?.id ??
          _addresses.first.id;
      setState(() => _busy = false);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AppDialog(
            title: AppStrings.reviewOrderTitle,
            cancelLabel: AppStrings.cancel,
            confirmLabel: AppStrings.createOrder,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.deliveryAddress),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedId,
                  isExpanded: true,
                  items: _addresses
                      .map(
                        (address) => DropdownMenuItem(
                          value: address.id,
                          child: Text(
                            AppStrings.addressOptionLabel(
                              address.label,
                              address.fullAddress,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedId = value);
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  AppStrings.orderOnlyNotice,
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _busy = true);
      final order = await widget.api.createOrder(shippingAddressId: selectedId);
      await _load();
      if (mounted) {
        showAppSnackBar(context, AppStrings.orderCreated(order.orderNumber));
      }
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object error) {
    showAppErrorSnackBar(
      context,
      error,
      fallback: AppStrings.errorRequestFailed,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.shoppingBagTitle)),
    body: _loading
        ? const SkeletonRowList()
        : _error != null
        ? ErrorStateView(message: _error!)
        : _cart!.items.isEmpty
        ? const Center(child: Text(AppStrings.bagEmpty))
        : Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cart!.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final item = _cart!.items[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: item.imageUrl == null
                              ? const SizedBox(
                                  width: 76,
                                  height: 90,
                                  child: Icon(Icons.checkroom_outlined),
                                )
                              : Image.network(
                                  item.imageUrl!,
                                  width: 76,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  webHtmlElementStrategy:
                                      WebHtmlElementStrategy.fallback,
                                  errorBuilder: (_, _, _) => const SizedBox(
                                    width: 76,
                                    height: 90,
                                    child: Icon(Icons.checkroom_outlined),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                AppStrings.variantSummary(
                                  item.size,
                                  item.color,
                                ),
                              ),
                              Text(
                                formatPrice(item.lineTotal, item.currencyCode),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _changeQuantity(
                                            item,
                                            item.quantity - 1,
                                          ),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                  Text('${item.quantity}'),
                                  IconButton(
                                    onPressed:
                                        _busy ||
                                            item.quantity >= item.stockQuantity
                                        ? null
                                        : () => _changeQuantity(
                                            item,
                                            item.quantity + 1,
                                          ),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: AppStrings.tooltipRemoveItem,
                                    onPressed: _busy
                                        ? null
                                        : () => _changeQuantity(item, 0),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text(AppStrings.subtotal)),
                          Text(
                            formatPrice(_cart!.subtotal, _cart!.currencyCode),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : _checkout,
                          child: Text(
                            _busy
                                ? AppStrings.pleaseWait
                                : AppStrings.continueToOrder,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
  );
}
