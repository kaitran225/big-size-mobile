import 'package:flutter/material.dart';

import '../shared/app_strings.dart';
import '../shared/widgets/not_implemented_view.dart';

/// Placeholder for the password reset request and confirmation screen.
class PasswordResetPage extends StatelessWidget {
  const PasswordResetPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.resetPassword)),
        body: const NotImplementedView(title: AppStrings.resetPassword),
      );
}
