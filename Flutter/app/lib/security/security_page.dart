import 'package:flutter/material.dart';

import '../shared/app_strings.dart';
import '../shared/widgets/app_info_note.dart';
import '../shared/widgets/app_list_tile_card.dart';
import '../shared/widgets/app_section_header.dart';
import 'email_verification_page.dart';
import 'otp_entry_page.dart';
import 'password_reset_page.dart';

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
          onTap: () => _open(context, const EmailVerificationPage()),
          isThreeLine: true,
        ),
        AppListTileCard(
          icon: Icons.password_outlined,
          title: AppStrings.resetPassword,
          subtitle: AppStrings.descriptionWithStatus(
            AppStrings.resetPasswordDescription,
            AppStrings.resetApiPending,
          ),
          onTap: () => _open(context, const PasswordResetPage()),
          isThreeLine: true,
        ),
        AppListTileCard(
          icon: Icons.pin_outlined,
          title: AppStrings.otpTitle,
          subtitle: AppStrings.descriptionWithStatus(
            AppStrings.otpDescription,
            AppStrings.otpApiPending,
          ),
          onTap: () => _open(context, const OtpEntryPage()),
          isThreeLine: true,
        ),
        const SizedBox(height: 12),
        const AppInfoNote(text: AppStrings.securityPreviewNotice),
      ],
    ),
  );

  static void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
