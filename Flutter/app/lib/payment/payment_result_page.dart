import 'package:flutter/material.dart';

import '../models/checkout_models.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';
import '../shared/theme/app_theme.dart';

/// Result of a sandbox payment attempt, shown after the provider callback.
class PaymentResultPage extends StatelessWidget {
  const PaymentResultPage({
    super.key,
    required this.result,
    required this.method,
    required this.amount,
    required this.currencyCode,
    this.orderNumber,
  });

  final SandboxPaymentResult result;
  final PaymentMethod method;
  final double amount;
  final String currencyCode;
  final String? orderNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final approved = result.approved;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          approved ? AppStrings.orderPlacedTitle : AppStrings.paymentDeclinedTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: approved ? AppColors.brandSoft : const Color(0xFFFBE9E7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                approved ? Icons.check_circle_outline : Icons.error_outline,
                size: 56,
                color: approved ? AppColors.brand : AppColors.danger,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            approved
                ? AppStrings.orderPlacedBody
                : AppStrings.paymentDeclinedBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _ResultRow(
                    label: AppStrings.paymentStepTitle,
                    value: _methodLabel(method),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ResultRow(
                    label: AppStrings.total,
                    value: formatPrice(amount, currencyCode),
                  ),
                  if (orderNumber != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _ResultRow(
                      label: AppStrings.ordersTitle,
                      value: orderNumber!,
                    ),
                  ],
                  if (result.reference.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _ResultRow(
                      label: AppStrings.paymentReference,
                      value: result.reference,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                approved ? AppStrings.continueShopping : AppStrings.tryAgain,
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
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
