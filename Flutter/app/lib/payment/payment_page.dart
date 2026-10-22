import 'package:flutter/material.dart';

import '../shared/app_strings.dart';
import '../shared/widgets/not_implemented_view.dart';

/// Placeholder for the payment method selection, which needs a provider API.
class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.paymentTitle)),
        body: const NotImplementedView(title: AppStrings.paymentTitle),
      );
}
