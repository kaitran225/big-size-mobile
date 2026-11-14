import 'package:flutter/material.dart';

import '../models/store_product.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';
import '../shared/theme/app_theme.dart';

class ProductTile extends StatefulWidget {
  const ProductTile({super.key, required this.product, required this.onTap});

  final StoreProduct product;
  final VoidCallback onTap;

  @override
  State<ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<ProductTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final available = product.variants.any(
      (variant) => variant.stockQuantity > 0,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product image.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: const Color(0xFFF3F3F3),
                    child:
                        product.imageUrl == null ||
                            product.imageUrl!.trim().isEmpty
                        ? _imagePlaceholder()
                        : Image.network(
                            product.imageUrl!,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            webHtmlElementStrategy:
                                WebHtmlElementStrategy.fallback,
                            errorBuilder: (context, error, stackTrace) {
                              return _imagePlaceholder();
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }

                              return const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Discount badge.
                  if (product.isOnSale)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        color: AppColors.sale,
                        child: Text(
                          AppStrings.discountBadge(product.discountPercent),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),

                  // Sold-out label.
                  if (!available)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        color: Colors.black.withValues(alpha: 0.85),
                        child: Text(
                          AppStrings.soldOut,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                  // Desktop hover action.
                  if (available && _isHovered)
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          onPressed: widget.onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          child: Text(
                            AppStrings.productViewAction,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Product name.
            SizedBox(
              height: 32,
              child: Text(
                product.name.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF171717),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                  letterSpacing: 0.25,
                ),
              ),
            ),

            const SizedBox(height: 5),

            // Product price.
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  formatPrice(product.currentPrice, product.currencyCode),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (product.isOnSale)
                  Text(
                    formatPrice(product.price, product.currencyCode),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 10,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF0F0F0),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checkroom_outlined, size: 36, color: Colors.black26),
          SizedBox(height: 8),
          Text(
            AppStrings.brandName,
            style: TextStyle(
              color: Colors.black38,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
