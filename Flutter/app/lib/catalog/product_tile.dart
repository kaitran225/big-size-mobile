import 'package:flutter/material.dart';

import '../models/store_product.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';

/// Grid tile that shows one product in the storefront.
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
                        AppStrings.discountBadge(product.discountPercent),
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
