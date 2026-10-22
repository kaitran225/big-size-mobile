import 'package:flutter/material.dart';

/// Dialog with a title, a body, and a cancel/confirm action pair.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final Widget content;
  final String confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: content,
    actions: [
      if (cancelLabel != null)
        TextButton(
          onPressed: onCancel ?? () => Navigator.pop(context, false),
          child: Text(cancelLabel!),
        ),
      FilledButton(
        onPressed: onConfirm ?? () => Navigator.pop(context, true),
        child: Text(confirmLabel),
      ),
    ],
  );
}
