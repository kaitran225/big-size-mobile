import 'package:flutter/material.dart';

import '../models/store_product.dart';
import '../shared/app_strings.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.session});

  final AuthSession? session;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.profileTitle)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CircleAvatar(
          radius: 36,
          child: Text(
            session?.displayName.isNotEmpty != true
                ? AppStrings.avatarFallback
                : session!.displayName.substring(0, 1).toUpperCase(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            session?.displayName ?? AppStrings.guest,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Center(child: Text(session?.email ?? AppStrings.signInToSaveProfile)),
        const SizedBox(height: 20),
        const _ProfileRow(
          icon: Icons.badge_outlined,
          title: AppStrings.accountType,
          subtitle: AppStrings.customerProfile,
        ),
        const _ProfileRow(
          icon: Icons.straighten_outlined,
          title: AppStrings.fitPreferences,
          subtitle: AppStrings.fitPreferencesValue,
        ),
        const _ProfileRow(
          icon: Icons.rate_review_outlined,
          title: AppStrings.myReviews,
          subtitle: AppStrings.reviewsNotConnected,
        ),
        const SizedBox(height: 12),
        const _ProfileNote(text: AppStrings.profileFrameNote),
      ],
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

class _ProfileNote extends StatelessWidget {
  const _ProfileNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodySmall,
    textAlign: TextAlign.center,
  );
}
