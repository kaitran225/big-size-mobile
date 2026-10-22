import 'package:flutter/material.dart';

import '../models/store_product.dart';
import '../shared/app_strings.dart';
import '../shared/widgets/app_info_note.dart';
import '../shared/widgets/app_list_tile_card.dart';

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
        const AppListTileCard(
          icon: Icons.badge_outlined,
          title: AppStrings.accountType,
          subtitle: AppStrings.customerProfile,
        ),
        const AppListTileCard(
          icon: Icons.straighten_outlined,
          title: AppStrings.fitPreferences,
          subtitle: AppStrings.fitPreferencesValue,
        ),
        const AppListTileCard(
          icon: Icons.rate_review_outlined,
          title: AppStrings.myReviews,
          subtitle: AppStrings.reviewsNotConnected,
        ),
        const SizedBox(height: 12),
        const AppInfoNote(
          text: AppStrings.profileFrameNote,
          style: AppInfoNoteStyle.plain,
        ),
      ],
    ),
  );
}
