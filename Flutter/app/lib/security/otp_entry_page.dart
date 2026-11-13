import 'package:flutter/material.dart';

import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/widgets/app_snack_bar.dart';

class OtpEntryPage extends StatefulWidget {
  const OtpEntryPage({super.key, required this.api});

  final StoreApi api;

  @override
  State<OtpEntryPage> createState() => _OtpEntryPageState();
}

class _OtpEntryPageState extends State<OtpEntryPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _busy = false;
  String? _devCode;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    setState(() {
      _busy = true;
      _devCode = null;
    });
    try {
      final preview = await widget.api.requestOtp(
        email: _emailController.text.trim(),
        purpose: 'login',
      );
      if (!mounted) return;
      setState(() {
        _devCode = preview;
        _busy = false;
      });
      showAppSnackBar(context, AppStrings.otpSent);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppErrorSnackBar(context, error);
    }
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    try {
      final ok = await widget.api.verifyOtp(
        email: _emailController.text.trim(),
        purpose: 'login',
        code: _codeController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (ok) {
        showAppSnackBar(context, AppStrings.otpVerified);
        Navigator.of(context).pop();
      } else {
        showAppErrorSnackBar(context, AppStrings.otpInvalid);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppStrings.otpTitle)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(AppStrings.otpDescription),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: AppStrings.email),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _request,
          child: Text(AppStrings.sendOtp),
        ),
        const Divider(height: 32),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: AppStrings.otpCodeLabel),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _verify,
          child: Text(AppStrings.verifyOtp),
        ),
        if (_devCode != null) ...[
          const SizedBox(height: 16),
          Text(
            AppStrings.devOtpHint(_devCode!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    ),
  );
}
