import 'package:flutter/material.dart';

import '../models/store_product.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';
import '../shared/widgets/skeleton_box.dart';

class ProductSkeletonCard extends StatelessWidget {
  const ProductSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      Expanded(child: SkeletonBox(borderRadius: 16)),
      SizedBox(height: 9),
      SkeletonBox(width: 120, height: 14),
      SizedBox(height: 7),
      SkeletonBox(width: 76, height: 14),
    ],
  );
}

class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product, required this.onTap});

  final StoreProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = product.variants.any(
      (variant) => variant.stockQuantity > 0,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: product.imageUrl == null
                      ? _imagePlaceholder()
                      : Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          webHtmlElementStrategy:
                              WebHtmlElementStrategy.fallback,
                          errorBuilder: (context, error, stackTrace) =>
                              _imagePlaceholder(),
                        ),
                ),
                if (product.isOnSale)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB43B31),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppStrings.discountOff(product.discountPercent),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                if (!available)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        AppStrings.soldOut,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                formatPrice(product.currentPrice, product.currencyCode),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: product.isOnSale
                      ? const Color(0xFFB43B31)
                      : Colors.black87,
                ),
              ),
              if (product.isOnSale) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    formatPrice(product.price, product.currencyCode),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: const Color(0xFFE8E7E2),
    child: const Center(
      child: Icon(Icons.checkroom_outlined, size: 38, color: Colors.black38),
    ),
  );
}

class ProductDetailsSheet extends StatefulWidget {
  const ProductDetailsSheet({
    super.key,
    required this.product,
    required this.onAddToBag,
    required this.onToggleFavorite,
  });

  final StoreProduct product;
  final Future<void> Function(StoreVariant variant) onAddToBag;
  final Future<void> Function() onToggleFavorite;

  @override
  State<ProductDetailsSheet> createState() => _ProductDetailsSheetState();
}

class _ProductDetailsSheetState extends State<ProductDetailsSheet> {
  StoreVariant? _selectedVariant;

  @override
  void initState() {
    super.initState();
    final availableVariants = widget.product.variants.where(
      (variant) => variant.stockQuantity > 0,
    );
    if (availableVariants.isNotEmpty) {
      _selectedVariant = availableVariants.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final sizes = product.variants
        .map((variant) => variant.size)
        .toSet()
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    product.imageUrl!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(height: 40),
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _PriceLine(product: product),
              if (product.description?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(product.description!),
              ],
              if (sizes.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  AppStrings.sizeAndColour,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: product.variants.map((variant) {
                    final selected = _selectedVariant?.id == variant.id;
                    return ChoiceChip(
                      label: Text(
                        AppStrings.variantSummary(variant.size, variant.color),
                      ),
                      selected: selected,
                      onSelected: variant.stockQuantity == 0
                          ? null
                          : (_) => setState(() => _selectedVariant = variant),
                      avatar: variant.stockQuantity == 0
                          ? const Icon(Icons.block, size: 14)
                          : null,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _selectedVariant == null
                      ? null
                      : () async {
                          await widget.onAddToBag(_selectedVariant!);
                          if (context.mounted) Navigator.pop(context);
                        },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(
                    _selectedVariant == null
                        ? AppStrings.currentlyUnavailable
                        : AppStrings.addToBag,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onToggleFavorite,
                  icon: const Icon(Icons.favorite_border),
                  label: const Text(AppStrings.addToFavorites),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.product});

  final StoreProduct product;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        formatPrice(product.currentPrice, product.currencyCode),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: product.isOnSale ? const Color(0xFFB43B31) : Colors.black87,
        ),
      ),
      if (product.isOnSale) ...[
        const SizedBox(width: 8),
        Text(
          formatPrice(product.price, product.currencyCode),
          style: const TextStyle(
            color: Colors.black54,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          AppStrings.discountOffLower(product.discountPercent),
          style: const TextStyle(
            color: Color(0xFFB43B31),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ],
  );
}
