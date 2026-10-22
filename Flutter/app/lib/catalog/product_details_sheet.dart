import 'package:flutter/material.dart';

import '../models/store_product.dart';
import '../shared/app_strings.dart';
import 'product_price_line.dart';

/// Bottom sheet that shows a product, its sizes, and the actions to add it to
/// the bag or to the favourites.
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
              ProductPriceLine(product: product),
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
