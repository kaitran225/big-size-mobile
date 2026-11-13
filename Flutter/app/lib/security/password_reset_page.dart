import 'package:flutter/material.dart';

import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/widgets/app_snack_bar.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key, required this.api});

  final StoreApi api;

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  bool _requested = false;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    setState(() => _busy = true);
    try {
      await widget.api.requestPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _busy = false;
        _requested = true;
      });
      showAppSnackBar(context, AppStrings.resetEmailSent);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppErrorSnackBar(context, error);
    }
  }

  Future<void> _completeReset() async {
    setState(() => _busy = true);
    try {
      await widget.api.completePasswordReset(
        token: _tokenController.text.trim(),
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      showAppSnackBar(context, AppStrings.resetPasswordSuccess);
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppStrings.resetPassword)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(AppStrings.resetPasswordDescription),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: AppStrings.email),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _requestReset,
          child: Text(AppStrings.requestResetEmail),
        ),
        if (_requested) ...[
          const Divider(height: 32),
          Text(AppStrings.enterResetToken),
          const SizedBox(height: 12),
          TextField(
            controller: _tokenController,
            decoration: InputDecoration(labelText: AppStrings.resetTokenLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: AppStrings.newPasswordLabel),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _completeReset,
            child: Text(AppStrings.saveNewPassword),
          ),
        ],
      ],
    ),
  );
}
