import 'package:flutter/material.dart';

import '../shared/app_strings.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.securityTitle)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          AppStrings.securityHeadline,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        const Text(AppStrings.securityIntro),
        const SizedBox(height: 16),
        const _SecurityStep(
          icon: Icons.mark_email_unread_outlined,
          title: AppStrings.verifyEmail,
          description: AppStrings.verifyEmailDescription,
          status: AppStrings.emailServicePending,
        ),
        const _SecurityStep(
          icon: Icons.password_outlined,
          title: AppStrings.resetPassword,
          description: AppStrings.resetPasswordDescription,
          status: AppStrings.resetApiPending,
        ),
        const _SecurityStep(
          icon: Icons.pin_outlined,
          title: AppStrings.otpTitle,
          description: AppStrings.otpDescription,
          status: AppStrings.otpApiPending,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(AppStrings.securityPreviewNotice),
        ),
      ],
    ),
  );
}

class _SecurityStep extends StatelessWidget {
  const _SecurityStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
  });

  final IconData icon;
  final String title;
  final String description;
  final String status;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text('$description\n$status'),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}
