import 'package:flutter/material.dart';

import '../models/store_product.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';

/// Price row that shows the current price, the original price, and the
/// discount for a product on sale.
class ProductPriceLine extends StatelessWidget {
  const ProductPriceLine({super.key, required this.product});

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
          AppStrings.discountText(product.discountPercent),
          style: const TextStyle(
            color: Color(0xFFB43B31),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ],
  );
}
