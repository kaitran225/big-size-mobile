import 'package:flutter/material.dart';

import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/widgets/app_snack_bar.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key, required this.api});

  final StoreApi api;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _sending = false;
  String? _devPreview;

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _devPreview = null;
    });
    try {
      final preview = await widget.api.requestEmailVerification();
      if (!mounted) return;
      setState(() {
        _devPreview = preview;
        _sending = false;
      });
      showAppSnackBar(context, AppStrings.verificationEmailSent);
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      showAppErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppStrings.verifyEmail)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(AppStrings.verifyEmailDescription),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: _sending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppStrings.sendVerificationEmail),
        ),
        if (_devPreview != null) ...[
          const SizedBox(height: 16),
          Text(
            AppStrings.devEmailLinkHint(_devPreview!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    ),
  );
}
