import 'package:flutter/material.dart';

import '../shared/app_strings.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _method = 'cod';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.paymentTitle)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          AppStrings.choosePaymentMethod,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        const Text(AppStrings.paymentTotalNote),
        const SizedBox(height: 16),
        _methodTile(
          value: 'cod',
          icon: Icons.local_shipping_outlined,
          title: AppStrings.paymentCod,
          subtitle: AppStrings.paymentCodSubtitle,
        ),
        _methodTile(
          value: 'bank',
          icon: Icons.account_balance_outlined,
          title: AppStrings.paymentBank,
          subtitle: AppStrings.paymentBankSubtitle,
        ),
        _methodTile(
          value: 'gateway',
          icon: Icons.credit_card_outlined,
          title: AppStrings.paymentGateway,
          subtitle: AppStrings.paymentGatewaySubtitle,
        ),
        const SizedBox(height: 12),
        const _IntegrationNote(text: AppStrings.paymentFrameNotice),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.paymentPreviewSnack)),
          ),
          child: const Text(AppStrings.continueAction),
        ),
      ],
    ),
  );

  Widget _methodTile({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _method == value;
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
        ),
        onTap: () => setState(() => _method = value),
      ),
    );
  }
}

class _IntegrationNote extends StatelessWidget {
  const _IntegrationNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
