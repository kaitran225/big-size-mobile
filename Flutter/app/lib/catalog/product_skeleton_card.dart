import 'package:flutter/material.dart';

import '../shared/widgets/skeleton_box.dart';

/// Placeholder tile shown while the product grid is loading.
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
