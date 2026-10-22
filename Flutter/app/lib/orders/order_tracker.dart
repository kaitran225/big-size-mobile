import 'package:flutter/material.dart';

import '../models/checkout_models.dart';
import '../shared/app_strings.dart';
import '../shared/theme/app_theme.dart';

/// Vertical timeline that shows where a shipment currently stands.
class ShipmentTracker extends StatelessWidget {
  const ShipmentTracker({super.key, required this.stage});

  final ShipmentStage stage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stages = ShipmentStage.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < stages.length; index++)
          _buildRow(theme, stages[index], index <= stage.index, index),
      ],
    );
  }

  Widget _buildRow(
    ThemeData theme,
    ShipmentStage stage,
    bool reached,
    int index,
  ) {
    final isLast = index == ShipmentStage.values.length - 1;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: reached ? AppColors.brand : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: reached ? AppColors.brand : AppColors.hairline,
                    width: 1.5,
                  ),
                ),
                child: reached
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: reached && index < ShipmentStage.values.length - 1
                        ? AppColors.brand
                        : AppColors.hairline,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stageLabel(stage),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: reached ? FontWeight.w700 : FontWeight.w500,
                      color: reached ? AppColors.ink : AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String stageLabel(ShipmentStage stage) => switch (stage) {
    ShipmentStage.placed => AppStrings.stagePlaced,
    ShipmentStage.confirmed => AppStrings.stageConfirmed,
    ShipmentStage.packed => AppStrings.stagePacked,
    ShipmentStage.shipped => AppStrings.stageShipped,
    ShipmentStage.outForDelivery => AppStrings.stageOutForDelivery,
    ShipmentStage.delivered => AppStrings.stageDelivered,
  };
}
