import 'package:flutter/material.dart';

import '../models/checkout_models.dart';
import '../shared/app_strings.dart';
import '../shared/theme/app_theme.dart';

/// Explains that live checkout happens in the bag, on the SePay sandbox.
class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.paymentTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Text(AppStrings.paymentHubBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          for (final method in const [
            PaymentMethod.cod,
            PaymentMethod.bankTransfer,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: ListTile(
                  title: Text(
                    _methodLabel(method),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(_methodNote(method)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _methodLabel(PaymentMethod method) => switch (method) {
    PaymentMethod.cod => AppStrings.paymentCod,
    PaymentMethod.bankTransfer => AppStrings.paymentBank,
    PaymentMethod.gateway => AppStrings.paymentGateway,
  };

  String _methodNote(PaymentMethod method) => switch (method) {
    PaymentMethod.cod => AppStrings.paymentCodSubtitle,
    PaymentMethod.bankTransfer => AppStrings.paymentBankSubtitle,
    PaymentMethod.gateway => AppStrings.paymentGatewaySubtitle,
  };
}
