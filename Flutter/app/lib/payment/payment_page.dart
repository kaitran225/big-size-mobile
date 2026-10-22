import 'package:flutter/material.dart';

import '../models/checkout_models.dart';
import '../shared/app_strings.dart';
import '../shared/theme/app_theme.dart';
import 'payment_result_page.dart';
import 'sandbox_gateway.dart';

/// Standalone sandbox payment screen used to demonstrate the provider flow.
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const SandboxGateway _gateway = SandboxGateway();

  PaymentMethod _method = PaymentMethod.gateway;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.paymentTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: AppColors.brand,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.secureCheckoutTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.brand,
                        ),
                      ),
                      Text(
                        AppStrings.sandboxBannerNote,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(AppStrings.paymentStepTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          RadioGroup<PaymentMethod>(
            groupValue: _method,
            onChanged: (method) {
              if (method != null) setState(() => _method = method);
            },
            child: Column(
              children: [
                for (final method in PaymentMethod.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Card(
                      child: RadioListTile<PaymentMethod>(
                        value: method,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        title: Text(
                          _methodLabel(method),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _pay,
              child: Text(
                _busy ? AppStrings.processingPayment : AppStrings.placeOrder,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pay() async {
    setState(() => _busy = true);
    final result = await _gateway.charge(
      method: _method,
      amount: 1499000,
      currencyCode: 'VND',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaymentResultPage(
          result: result,
          method: _method,
          amount: 1499000,
          currencyCode: 'VND',
        ),
      ),
    );
  }

  String _methodLabel(PaymentMethod method) => switch (method) {
    PaymentMethod.cod => AppStrings.paymentCod,
    PaymentMethod.bankTransfer => AppStrings.paymentBank,
    PaymentMethod.gateway => AppStrings.paymentGateway,
  };
}
