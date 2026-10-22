import 'package:flutter/material.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account security')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Protect your BigFit account',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        const Text('These flows are ready for email and OTP service wiring.'),
        const SizedBox(height: 16),
        const _SecurityStep(
          icon: Icons.mark_email_unread_outlined,
          title: 'Verify your email',
          description: 'Confirm your email address with a one-time link.',
          status: 'Email service pending',
        ),
        const _SecurityStep(
          icon: Icons.password_outlined,
          title: 'Reset password',
          description: 'Request a secure password reset email.',
          status: 'Reset API pending',
        ),
        const _SecurityStep(
          icon: Icons.pin_outlined,
          title: 'One-time passcode',
          description: 'Enter a time-limited code sent to your email.',
          status: 'OTP API pending',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'UI preview only. Email delivery, OTP verification, retry limits, and password reset are not active.',
          ),
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
