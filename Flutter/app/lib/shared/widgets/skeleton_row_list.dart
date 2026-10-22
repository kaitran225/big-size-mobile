import 'package:flutter/material.dart';

import 'skeleton_box.dart';

/// Placeholder list shown while cart lines are loading.
class SkeletonRowList extends StatelessWidget {
  const SkeletonRowList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: itemCount,
    separatorBuilder: (_, _) => const SizedBox(height: 20),
    itemBuilder: (context, index) => const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(width: 76, height: 90, borderRadius: 12),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 150),
              SizedBox(height: 9),
              SkeletonBox(width: 100),
              SizedBox(height: 16),
              SkeletonBox(width: 80),
            ],
          ),
        ),
      ],
    ),
  );
}
