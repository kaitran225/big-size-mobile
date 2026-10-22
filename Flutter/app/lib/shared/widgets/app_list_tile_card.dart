import 'package:flutter/material.dart';

/// A card that shows a leading icon, a title, an optional subtitle, and a
/// trailing affordance. Used for every tappable row in the app.
class AppListTileCard extends StatelessWidget {
  const AppListTileCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.isThreeLine = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isThreeLine;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      isThreeLine: isThreeLine,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
