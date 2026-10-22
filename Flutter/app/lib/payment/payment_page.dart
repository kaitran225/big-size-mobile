import 'package:flutter/material.dart';

import '../shared/app_strings.dart';
import '../shared/widgets/app_info_note.dart';
import '../shared/widgets/app_list_tile_card.dart';
import '../shared/widgets/app_section_header.dart';
import '../shared/widgets/app_snack_bar.dart';

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
        const AppSectionHeader(text: AppStrings.choosePaymentMethod),
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
        const AppInfoNote(text: AppStrings.paymentFrameNotice),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () =>
              showAppSnackBar(context, AppStrings.paymentPreviewSnack),
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
    return AppListTileCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
      ),
      onTap: () => setState(() => _method = value),
    );
  }
}
