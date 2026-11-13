import 'dart:async';

import 'package:flutter/material.dart';

import '../cart/sandbox_qr_image.dart';
import '../models/checkout_models.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';

/// Shows the transfer amount and waits until the Bank Hub IPN confirms it.
class SePayCheckoutPage extends StatefulWidget {
  const SePayCheckoutPage({
    super.key,
    required this.api,
    required this.payment,
  });

  final StoreApi api;
  final PaymentSession payment;

  @override
  State<SePayCheckoutPage> createState() => _SePayCheckoutPageState();
}

class _SePayCheckoutPageState extends State<SePayCheckoutPage> {
  Timer? _poll;
  var _busy = false;
  var _finished = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_finished) return;
    try {
      final latest = await widget.api.latestPayment(widget.payment.orderId);
      if (!mounted || _finished) return;
      if (latest.status == 'Succeeded') {
        _finish('success');
      } else if (latest.status == 'Failed' || latest.status == 'Cancelled') {
        _finish('error');
      }
    } catch (_) {
      // The next poll retries. A transient local-network miss should not cancel checkout.
    }
  }

  Future<void> _simulate() async {
    if (widget.payment.id.isEmpty) {
      setState(() => _error = AppStrings.errorRequestFailed);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.simulatePayment(
        orderId: widget.payment.orderId,
        paymentId: widget.payment.id,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  void _finish(String result) {
    if (_finished || !mounted) return;
    _finished = true;
    _poll?.cancel();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final fields = widget.payment.checkoutFields;
    final amount = widget.payment.amount.toStringAsFixed(0);
    final content = fields['transferContent'] ?? '';
    final bankCode = fields['bankCode'] ?? '';
    final accountNumber = fields['accountNumber'] ?? '';
    final accountHolder = fields['accountHolderName'] ?? '';
    final qrUrl = _qrUrl(
      bankBin: fields['bankBin'] ?? '',
      accountNumber: accountNumber,
      amount: amount,
      content: content,
      accountHolder: accountHolder,
    );
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.paymentTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _finish('cancel'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            AppStrings.waitingForBankHub,
            style: theme.textTheme.titleMedium,
          ),
          if (qrUrl != null) ...[
            const SizedBox(height: 24),
            Center(child: sandboxQrImage(qrUrl)),
          ],
          const SizedBox(height: 24),
          Text(
            '$amount ${widget.payment.currencyCode}',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _detail(theme, AppStrings.bankCodeLabel, bankCode),
          _detail(theme, AppStrings.accountNumberLabel, accountNumber),
          _detail(theme, AppStrings.accountHolderLabel, accountHolder),
          _detail(theme, AppStrings.transferContentLabel, content),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _simulate,
            child: Text(
              _busy
                  ? AppStrings.processingPayment
                  : AppStrings.simulateSandboxPayment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(ThemeData theme, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          SelectableText(value, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }

  String? _qrUrl({
    required String bankBin,
    required String accountNumber,
    required String amount,
    required String content,
    required String accountHolder,
  }) {
    if (bankBin.isEmpty || accountNumber.isEmpty) return null;
    return Uri.https(
      'img.vietqr.io',
      'image/$bankBin-$accountNumber-compact2.png',
      {'amount': amount, 'addInfo': content, 'accountName': accountHolder},
    ).toString();
  }
}
