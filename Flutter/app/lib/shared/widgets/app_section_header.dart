import 'package:flutter/material.dart';

/// Heading that separates groups of cards inside a page.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleLarge);
}
