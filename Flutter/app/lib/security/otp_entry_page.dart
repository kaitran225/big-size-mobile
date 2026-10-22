import 'package:flutter/material.dart';

import '../shared/app_strings.dart';
import '../shared/widgets/not_implemented_view.dart';

/// Placeholder for the one-time passcode entry screen.
class OtpEntryPage extends StatelessWidget {
  const OtpEntryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.otpTitle)),
        body: const NotImplementedView(title: AppStrings.otpTitle),
      );
}
