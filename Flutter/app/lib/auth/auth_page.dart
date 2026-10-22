import 'package:flutter/material.dart';

import '../models/store_product.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/app_snack_bar.dart';

/// Dedicated sign-in and registration screen.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.api});

  final StoreApi api;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _obscurePassword = true;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final session = _isRegistering
          ? await widget.api.registerCustomer(
              email: _emailController.text,
              displayName: _nameController.text,
              password: _passwordController.text,
            )
          : await widget.api.login(
              _emailController.text,
              _passwordController.text,
            );
      if (!mounted) return;
      Navigator.of(context).pop<AuthSession>(session);
    } catch (error) {
      if (!mounted) return;
      showAppErrorSnackBar(context, error, fallback: AppStrings.errorSignIn);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isRegistering ? AppStrings.joinBigFit : AppStrings.welcomeBack,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.brandName,
                          style: theme.textTheme.labelLarge?.copyWith(
                            letterSpacing: 2.4,
                            color: AppColors.brand,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _isRegistering
                              ? AppStrings.joinBigFit
                              : AppStrings.welcomeBack,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _isRegistering
                              ? AppStrings.registerSubtitle
                              : AppStrings.loginSubtitle,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_isRegistering) ...[
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: AppStrings.displayName,
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) =>
                                (value == null || value.trim().length < 2)
                                ? AppStrings.validationDisplayName
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: AppStrings.email,
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: (value) =>
                              value != null &&
                                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                      .hasMatch(value.trim())
                              ? null
                              : AppStrings.validationEmail,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: [
                            _isRegistering
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: AppStrings.password,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => _isRegistering
                              ? (value == null || value.length < 12)
                                    ? AppStrings.validationPasswordLength
                                    : null
                              : (value == null || value.isEmpty)
                              ? AppStrings.validationPasswordRequired
                              : null,
                        ),
                      ],
                    ),
                  ),
                  if (_isRegistering) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppStrings.passwordPolicyHint,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isRegistering
                                ? AppStrings.createAccount
                                : AppStrings.signIn,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () =>
                              setState(() => _isRegistering = !_isRegistering),
                    child: Text(
                      _isRegistering
                          ? AppStrings.switchToSignIn
                          : AppStrings.switchToRegister,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
