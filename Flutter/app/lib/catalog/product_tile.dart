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
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
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

                // Product discount badge.
                if (product.isOnSale)
                  Positioned(
                    top: 9,
                    left: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      color: Colors.black,
                      child: Text(
                        AppStrings.discountBadge(product.discountPercent),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                // Sold-out badge.
                if (!available)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      color: Colors.black,
                      child: const Text(
                        AppStrings.soldOut,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Product name.
          Text(
            product.name.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 7),

          // Product price.
          Row(
            children: [
              Text(
                formatPrice(product.currentPrice, product.currencyCode),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
              if (product.isOnSale) ...[
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    formatPrice(product.price, product.currencyCode),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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
        color: const Color(0xFFF0F0F0),
        child: const Center(
          child: Icon(
            Icons.checkroom_outlined,
            size: 38,
            color: Colors.black38,
          ),
        ),
      );
}