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
    final theme = Theme.of(context);
    final product = widget.product;
    final variant = _selectedVariant;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.canvas,
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
                color: AppColors.surface,
                child: _HeroImage(url: product.imageUrl),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.brandName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(product.name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.md),
                  ProductPriceLine(product: product),
                  if (product.description?.isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      product.description!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    AppStrings.selectSize,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (variant == null)
                    Text(
                      AppStrings.selectSizeFirst,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.danger,
                      ),
                    )
                  else
                    Text(
                      AppStrings.onlyLeft(variant.stockQuantity),
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: AppSpacing.md),
                  _buildVariantGrid(),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Text(
                        AppStrings.quantity,
                        style: theme.textTheme.titleMedium,
                      ),
                      const Spacer(),
                      _buildQuantityStepper(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildPerks(),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    AppStrings.productOverview,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    product.description?.isNotEmpty == true
                        ? product.description!
                        : AppStrings.productCareNote,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    AppStrings.productCare,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.productCareNote,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppStrings.fitGuaranteeNote,
                    style: theme.textTheme.bodySmall,
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

  Widget _buildVariantGrid() => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: widget.product.variants.map((variant) {
      final selected = _selectedVariant?.id == variant.id;
      final soldOut = variant.stockQuantity == 0;
      return ChoiceChip(
        label: Text(AppStrings.variantSummary(variant.size, variant.color)),
        selected: selected,
        onSelected: soldOut
            ? null
            : (_) => setState(() {
                _selectedVariant = variant;
                _quantity = 1;
              }),
        avatar: soldOut ? const Icon(Icons.block, size: 14) : null,
      );
    }).toList(),
  );

  Widget _buildQuantityStepper() => Container(
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.hairline),
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _quantity > 1
              ? () => setState(() => _quantity -= 1)
              : null,
          icon: const Icon(Icons.remove),
        ),
        Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(
          onPressed: _quantity < (_selectedVariant?.stockQuantity ?? 0)
              ? () => setState(() => _quantity += 1)
              : null,
          icon: const Icon(Icons.add),
        ),
      ],
    ),
  );

  Widget _buildPerks() => Row(
    children: [
      Expanded(
        child: _PerkTile(
          icon: Icons.local_shipping_outlined,
          label: AppStrings.freeDeliveryNote,
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: _PerkTile(
          icon: Icons.swap_horiz,
          label: AppStrings.easyReturnsNote,
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: _PerkTile(
          icon: Icons.lock_outline,
          label: AppStrings.securePaymentNote,
        ),
      ),
    ],
  );

  Widget _buildActionBar(StoreVariant? variant) {
    final product = widget.product;
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.total,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    formatPrice(
                      product.currentPrice * _quantity,
                      product.currencyCode,
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: variant == null || _busy
                            ? null
                            : () => _addToBag(variant),
                        child: Text(
                          _busy ? AppStrings.pleaseWait : AppStrings.addToBag,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: variant == null || _busy
                            ? null
                            : () => _buyNow(variant),
                        child: Text(
                          _busy ? AppStrings.pleaseWait : AppStrings.buyNow,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
      showAppErrorSnackBar(context, error, fallback: AppStrings.errorAddToBag);
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
        MaterialPageRoute<void>(builder: (_) => CheckoutPage(api: widget.api)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppErrorSnackBar(context, error, fallback: AppStrings.errorAddToBag);
    }
  }

  Future<bool> _ensureSignedIn() async {
    final session = await widget.api.loadSession();
    if (session != null) return true;
    if (!mounted) return false;
    final result = await Navigator.of(context).push<AuthSession>(
      MaterialPageRoute<AuthSession>(builder: (_) => AuthPage(api: widget.api)),
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
      errorBuilder: (context, error, stackTrace) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFEDE9E1),
    child: const Center(
      child: Icon(Icons.checkroom_outlined, size: 72, color: Colors.black26),
    ),
  );
}

class _PerkTile extends StatelessWidget {
  const _PerkTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.brandSoft,
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.brand),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    ),
  );
}
