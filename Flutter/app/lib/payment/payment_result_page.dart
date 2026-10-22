import 'package:flutter/material.dart';

import '../shared/app_strings.dart';
import '../shared/widgets/not_implemented_view.dart';

/// Placeholder for the payment result screen shown after a provider callback.
class PaymentResultPage extends StatelessWidget {
  const PaymentResultPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.paymentResultTitle)),
        body: const NotImplementedView(title: AppStrings.paymentResultTitle),
      );
}
