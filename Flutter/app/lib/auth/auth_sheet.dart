import 'package:flutter/material.dart';

import '../services/store_api.dart';
import '../shared/app_strings.dart';

class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key, required this.api});

  final StoreApi api;

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = _register
          ? await widget.api.registerCustomer(
              email: _emailController.text,
              displayName: _nameController.text,
              password: _passwordController.text,
            )
          : await widget.api.login(
              _emailController.text,
              _passwordController.text,
            );
      if (mounted) Navigator.pop(context, session);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is StoreApiException
            ? error.message
            : AppStrings.errorSignIn;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _register ? AppStrings.joinBigFit : AppStrings.welcomeBack,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                _register
                    ? AppStrings.registerSubtitle
                    : AppStrings.loginSubtitle,
              ),
              const SizedBox(height: 20),
              if (_register) ...[
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: AppStrings.displayName,
                  ),
                  validator: (value) => value == null || value.trim().length < 2
                      ? AppStrings.validationDisplayName
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: AppStrings.email),
                validator: (value) =>
                    value == null ||
                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)
                    ? AppStrings.validationEmail
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: AppStrings.password,
                ),
                validator: (value) =>
                    value == null || value.length < (_register ? 12 : 1)
                    ? _register
                          ? AppStrings.validationPasswordLength
                          : AppStrings.validationPasswordRequired
                    : null,
              ),
              if (_register) ...[
                const SizedBox(height: 8),
                const Text(
                  AppStrings.passwordPolicyHint,
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFB43B31))),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _register
                              ? AppStrings.createAccount
                              : AppStrings.signIn,
                        ),
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _register = !_register;
                        _error = null;
                      }),
                child: Text(
                  _register
                      ? AppStrings.switchToSignIn
                      : AppStrings.switchToRegister,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
