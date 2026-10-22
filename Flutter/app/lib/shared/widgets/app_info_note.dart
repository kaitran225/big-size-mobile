import 'package:flutter/material.dart';

/// Visual treatments available to [AppInfoNote].
enum AppInfoNoteStyle {
  /// Tinted container with a leading info icon.
  filled,

  /// Outlined card that only holds the text.
  bordered,

  /// Plain centred caption, used for short footnotes.
  plain,
}

/// An explanatory note that explains what is wired up and what is not.
class AppInfoNote extends StatelessWidget {
  const AppInfoNote({
    super.key,
    required this.text,
    this.style = AppInfoNoteStyle.filled,
    this.icon = Icons.info_outline,
  });

  final String text;
  final AppInfoNoteStyle style;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case AppInfoNoteStyle.plain:
        return Text(
          text,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        );
      case AppInfoNoteStyle.bordered:
        return Card(
          child: Padding(padding: const EdgeInsets.all(14), child: Text(text)),
        );
      case AppInfoNoteStyle.filled:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
            ],
          ),
        );
    }
  }
}
