import 'package:flutter/material.dart';

import '../shared/app_strings.dart';
import '../shared/widgets/app_info_note.dart';
import '../shared/widgets/app_list_tile_card.dart';
import '../shared/widgets/app_section_header.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.securityTitle)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AppSectionHeader(text: AppStrings.securityHeadline),
        const SizedBox(height: 6),
        const Text(AppStrings.securityIntro),
        const SizedBox(height: 16),
        AppListTileCard(
          icon: Icons.mark_email_unread_outlined,
          title: AppStrings.verifyEmail,
          subtitle: AppStrings.descriptionWithStatus(
            AppStrings.verifyEmailDescription,
            AppStrings.emailServicePending,
          ),
          isThreeLine: true,
        ),
        AppListTileCard(
          icon: Icons.password_outlined,
          title: AppStrings.resetPassword,
          subtitle: AppStrings.descriptionWithStatus(
            AppStrings.resetPasswordDescription,
            AppStrings.resetApiPending,
          ),
          isThreeLine: true,
        ),
        AppListTileCard(
          icon: Icons.pin_outlined,
          title: AppStrings.otpTitle,
          subtitle: AppStrings.descriptionWithStatus(
            AppStrings.otpDescription,
            AppStrings.otpApiPending,
          ),
          isThreeLine: true,
        ),
        const SizedBox(height: 12),
        const AppInfoNote(text: AppStrings.securityPreviewNotice),
      ],
    ),
  );
}
