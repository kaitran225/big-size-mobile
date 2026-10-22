import 'package:flutter/material.dart';

import 'skeleton_box.dart';

/// Placeholder list shown while address records are loading.
class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: itemCount,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (context, index) => const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 130),
            SizedBox(height: 10),
            SkeletonBox(width: 180),
            SizedBox(height: 8),
            SkeletonBox(width: 220),
          ],
        ),
      ),
    ),
  );
}
