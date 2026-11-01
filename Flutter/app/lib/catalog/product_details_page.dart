import 'package:flutter/material.dart';

import '../auth/auth_page.dart';
import '../cart/cart_page.dart';
import '../cart/checkout_page.dart';
import '../models/store_product.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/app_snack_bar.dart';
import 'product_price_line.dart';

/// Full page for one product with size selection and bag actions.
class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({
    super.key,
    required this.api,
    required this.product,
  });

  final StoreApi api;
  final StoreProduct product;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  StoreVariant? _selectedVariant;
  int _quantity = 1;
  bool _busy = false;

  @override
  void initState() {
    super.initState();

    final available = widget.product.variants.where(
      (variant) => variant.stockQuantity > 0,
    );

    if (available.isNotEmpty) {
      _selectedVariant = available.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final variant = _selectedVariant;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            actions: [
              IconButton(
                tooltip: AppStrings.shoppingBagTitle,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CartPage(api: widget.api),
                  ),
                ),
                icon: const Icon(Icons.shopping_bag_outlined),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ColoredBox(
                color: const Color(0xFFF3F3F3),
                child: _HeroImage(url: product.imageUrl),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                24,
                20,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.brandName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    product.name.toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 14),

                  ProductPriceLine(product: product),

                  if (product.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    Text(
                      product.description!,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  _sectionTitle(AppStrings.selectSize),

                  const SizedBox(height: 10),

                  if (variant == null)
                    Text(
                      AppStrings.selectSizeFirst,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      AppStrings.onlyLeft(variant.stockQuantity),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),

                  const SizedBox(height: 16),

                  _buildVariantGrid(),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      _sectionTitle(AppStrings.quantity),
                      const Spacer(),
                      _buildQuantityStepper(),
                    ],
                  ),

                  const SizedBox(height: 30),

                  _buildPerks(),

                  const SizedBox(height: 30),

                  _sectionTitle(AppStrings.productOverview),

                  const SizedBox(height: 12),

                  Text(
                    product.description?.isNotEmpty == true
                        ? product.description!
                        : AppStrings.productCareNote,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _sectionTitle(AppStrings.productCare),

                  const SizedBox(height: 12),

                  Text(
                    AppStrings.productCareNote,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    AppStrings.fitGuaranteeNote,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionBar(variant),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildVariantGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: widget.product.variants.map((variant) {
        final selected = _selectedVariant?.id == variant.id;
        final soldOut = variant.stockQuantity == 0;

        return ChoiceChip(
          label: Text(
            AppStrings.variantSummary(variant.size, variant.color),
          ),
          selected: selected,
          onSelected: soldOut
              ? null
              : (_) {
                  setState(() {
                    _selectedVariant = variant;
                    _quantity = 1;
                  });
                },
          avatar: soldOut
              ? const Icon(Icons.block, size: 14)
              : null,
          selectedColor: Colors.black,
          backgroundColor: Colors.white,
          disabledColor: const Color(0xFFF0F0F0),
          side: BorderSide(
            color: selected ? Colors.black : const Color(0xFFDDDDDD),
          ),
          labelStyle: TextStyle(
            color: selected
                ? Colors.white
                : soldOut
                    ? Colors.black38
                    : Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildQuantityStepper() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _quantity > 1
                ? () => setState(() => _quantity -= 1)
                : null,
            icon: const Icon(Icons.remove, size: 18),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: _quantity <
                    (_selectedVariant?.stockQuantity ?? 0)
                ? () => setState(() => _quantity += 1)
                : null,
            icon: const Icon(Icons.add, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildPerks() {
    return Row(
      children: [
        Expanded(
          child: _PerkTile(
            icon: Icons.local_shipping_outlined,
            label: AppStrings.freeDeliveryNote,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PerkTile(
            icon: Icons.swap_horiz,
            label: AppStrings.easyReturnsNote,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PerkTile(
            icon: Icons.lock_outline,
            label: AppStrings.securePaymentNote,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(StoreVariant? variant) {
    final product = widget.product;

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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Flexible(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.total.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatPrice(
                        product.currentPrice * _quantity,
                        product.currencyCode,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                flex: 6,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black),
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: variant == null || _busy
                            ? null
                            : () => _addToBag(variant),
                        child: Text(
                          _busy
                              ? AppStrings.pleaseWait
                              : AppStrings.addToBag,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: variant == null || _busy
                            ? null
                            : () => _buyNow(variant),
                        child: Text(
                          _busy
                              ? AppStrings.pleaseWait
                              : AppStrings.buyNow,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToBag(StoreVariant variant) async {
    if (!await _ensureSignedIn()) return;

    setState(() => _busy = true);

    try {
      await widget.api.addCartItem(
        productVariantId: variant.id,
        quantity: _quantity,
      );

      if (!mounted) return;

      setState(() => _busy = false);

      showAppSnackBar(
        context,
        AppStrings.addedToBag(widget.product.name, variant.size),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _busy = false);

      showAppErrorSnackBar(
        context,
        error,
        fallback: AppStrings.errorAddToBag,
      );
    }
  }

  Future<void> _buyNow(StoreVariant variant) async {
    if (!await _ensureSignedIn()) return;

    setState(() => _busy = true);

    try {
      await widget.api.addCartItem(
        productVariantId: variant.id,
        quantity: _quantity,
      );

      if (!mounted) return;

      setState(() => _busy = false);

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CheckoutPage(api: widget.api),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _busy = false);

      showAppErrorSnackBar(
        context,
        error,
        fallback: AppStrings.errorAddToBag,
      );
    }
  }

  Future<bool> _ensureSignedIn() async {
    final session = await widget.api.loadSession();

    if (session != null) return true;
    if (!mounted) return false;

    final result = await Navigator.of(context).push<AuthSession>(
      MaterialPageRoute<AuthSession>(
        builder: (_) => AuthPage(api: widget.api),
      ),
    );

    return result != null;
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) return const _ImageFallback();

    return Image.network(
      url!,
      fit: BoxFit.contain,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (context, error, stackTrace) =>
          const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F1F1),
      child: const Center(
        child: Icon(
          Icons.checkroom_outlined,
          size: 72,
          color: Colors.black26,
        ),
      ),
    );
  }
}

class _PerkTile extends StatelessWidget {
  const _PerkTile({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.black,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}