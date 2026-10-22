import 'package:flutter/material.dart';

/// Full-page placeholder shown when a collection has no items yet.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key, this.icon, this.title, this.message});

  final IconData? icon;
  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (icon == null && title == null) {
      return Center(child: Text(message ?? '', textAlign: TextAlign.center));
    }
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 46),
              const SizedBox(height: 14),
            ],
            if (title != null)
              Text(
                title!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (title != null && message != null) const SizedBox(height: 8),
            if (message != null) Text(message!, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
