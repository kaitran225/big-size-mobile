import 'package:flutter/material.dart';

import '../app_strings.dart';

/// Full-page message shown when a request failed.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    this.icon,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    if (icon == null && onRetry == null) {
      return Center(child: Text(message, textAlign: TextAlign.center));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 42),
              const SizedBox(height: 12),
            ],
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel ?? AppStrings.tryAgain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
