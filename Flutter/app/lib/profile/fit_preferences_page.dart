import 'package:flutter/material.dart';

import '../shared/app_strings.dart';
import '../shared/widgets/not_implemented_view.dart';

/// Placeholder for the fit and size preference form.
class FitPreferencesPage extends StatelessWidget {
  const FitPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.fitPreferences)),
        body: const NotImplementedView(title: AppStrings.fitPreferences),
      );
}
