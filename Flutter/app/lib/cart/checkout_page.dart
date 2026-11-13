import 'package:flutter/material.dart';

import '../map/map_point_picker.dart';
import 'sandbox_qr_image.dart';
import '../models/checkout_models.dart';
import '../models/store_product.dart';
import '../orders/order_detail_page.dart';
import '../payment/payment_result_page.dart';
import '../payment/sepay_checkout_page.dart';
import '../services/shipment_board.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/app_snack_bar.dart';

/// Checkout flow: contact, delivery address, then COD or SePay sandbox.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.api});

  final StoreApi api;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _contactFormKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<FormState>();
  final _contactControllers = <String, TextEditingController>{
    'label': TextEditingController(text: AppStrings.defaultAddressLabel),
    'recipientName': TextEditingController(),
    'phoneNumber': TextEditingController(),
  };
  final _addressControllers = <String, TextEditingController>{
    'addressLine': TextEditingController(),
    'city': TextEditingController(),
    'province': TextEditingController(),
    'postalCode': TextEditingController(),
    'countryCode': TextEditingController(text: AppStrings.defaultCountryCode),
  };

  CheckoutStep _step = CheckoutStep.contact;
  Cart? _cart;
  List<CustomerAddress> _addresses = [];
  CustomerAddress? _selectedAddress;
  double? _latitude;
  double? _longitude;
  PaymentMethod _method = PaymentMethod.bankTransfer;
  bool _busy = false;
  bool _awaitingConfirmation = false;
  String? _error;
  String? _paymentError;
  CustomerOrder? _order;
  PaymentSession? _payment;

  static const _sandboxBankBin = '970422';
  static const _sandboxAccountNumber = '0123456789';
  static const _sandboxAccountHolder = 'NGUYEN VAN A';
  static const _eurToVndRate = 27000;
  static const _offeredMethods = [PaymentMethod.cod, PaymentMethod.bankTransfer];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _contactControllers.values) {
      controller.dispose();
    }
    for (final controller in _addressControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        widget.api.getCart(),
        widget.api.getAddresses(),
      ]);
      if (!mounted) return;
      setState(() {
        _cart = results[0] as Cart;
        _addresses = results[1] as List<CustomerAddress>;
        final defaultAddr = _addresses.where((a) => a.isDefault).firstOrNull ??
            _addresses.firstOrNull;
        if (defaultAddr != null) {
          _selectAddress(defaultAddr);
        }
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is StoreApiException
            ? error.message
            : AppStrings.errorLoadBag;
        _busy = false;
      });
    }
  }

  Future<void> _saveNewContact() async {
    if (!_contactFormKey.currentState!.validate()) return;
    final addressLine = _addressControllers['addressLine']!.text.trim();
    final city = _addressControllers['city']!.text.trim();
    if (addressLine.isEmpty || city.isEmpty) {
      setState(() => _error = AppStrings.required);
      return;
    }
    setState(() => _busy = true);
    try {
      final saved = await widget.api.saveAddress({
        'label': _contactControllers['label']!.text.trim(),
        'recipientName': _contactControllers['recipientName']!.text.trim(),
        'phoneNumber': _contactControllers['phoneNumber']!.text.trim(),
        'addressLine': addressLine,
        'city': city,
        'province': _addressControllers['province']!.text.trim(),
        'postalCode': _addressControllers['postalCode']!.text.trim(),
        'countryCode': _addressControllers['countryCode']!.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'isDefault': false,
      });
      if (!mounted) return;
      setState(() {
        _addresses = [..._addresses, saved];
        _selectedAddress = saved;
        _busy = false;
        _step = CheckoutStep.payment;
      });
      showAppSnackBar(context, AppStrings.contactSaved);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(error);
    }
  }

  Future<void> _saveDeliveryPoint() async {
    final address = _selectedAddress;
    if (address == null) return;
    if (!_addressFormKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final saved = await widget.api.saveAddress({
        'label': address.label,
        'recipientName': address.recipientName,
        'phoneNumber': address.phoneNumber,
        'addressLine': _addressControllers['addressLine']!.text.trim(),
        'city': _addressControllers['city']!.text.trim(),
        'province': _addressControllers['province']!.text.trim(),
        'postalCode': _addressControllers['postalCode']!.text.trim(),
        'countryCode': _addressControllers['countryCode']!.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'isDefault': address.isDefault,
      }, id: address.id);
      if (!mounted) return;
      setState(() {
        _addresses = [
          for (final item in _addresses)
            if (item.id == saved.id) saved else item,
        ];
        _selectedAddress = saved;
        _busy = false;
        _step = CheckoutStep.payment;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(error);
    }
  }

  void _openPaymentStep() {
    setState(() => _step = CheckoutStep.payment);
  }

  Future<void> _placeOrder() async {
    final address = _selectedAddress;
    if (address == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _paymentError = null;
    });
    if (_method == PaymentMethod.bankTransfer) {
      await _placeBankTransfer(address);
      return;
    }
    try {
      if (_awaitingConfirmation && _order != null) {
        final latest = await _waitForPayment(_order!.id);
        if (!mounted) return;
        if (latest.status == 'Succeeded') {
          await _complete(latest);
        } else {
          setState(() {
            _payment = latest;
            _paymentError = AppStrings.paymentWaitingBody;
            _busy = false;
          });
        }
        return;
      }

      final order = _order ??
          await widget.api.createOrder(shippingAddressId: address.id);
      _order = order;
      final payment = await widget.api.createPayment(
        orderId: order.id,
        method: _method.name,
      );
      if (!mounted) return;
      await _complete(payment);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(error);
    }
  }

  Future<void> _placeBankTransfer(CustomerAddress address) async {
    CustomerOrder? order = _order;
    PaymentSession? payment = _payment;
    try {
      order ??= await widget.api.createOrder(shippingAddressId: address.id);
      _order = order;
      if (payment == null || !payment.awaitsTransfer) {
        payment = await widget.api.createPayment(
          orderId: order.id,
          method: PaymentMethod.bankTransfer.name,
        );
        _payment = payment;
      }
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
    if (!mounted) return;
    final session = _transferSession(payment, order);
    setState(() => _busy = false);
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SePayCheckoutPage(api: widget.api, payment: session),
      ),
    );
    if (!mounted) return;
    final realPayment = payment;
    final realOrder = order;
    if (result == 'success') {
      await _finishDisplayedTransfer(session, realOrder);
      return;
    }
    if (realPayment == null || realPayment.id.isEmpty || realOrder == null) {
      return;
    }
    if (result != 'success') {
      try {
        final reported = await widget.api.reportPaymentResult(
          orderId: realOrder.id,
          paymentId: realPayment.id,
          result: result == 'error' ? 'error' : 'cancel',
        );
        if (!mounted) return;
        if (reported.status == 'Succeeded') {
          await _complete(reported);
          return;
        }
        setState(() {
          _payment = reported;
          _awaitingConfirmation = false;
          _busy = false;
        });
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PaymentResultPage(
              approved: false,
              method: _method,
              amount: reported.amount,
              currencyCode: reported.currencyCode,
              reference: reported.providerReference ?? '',
              orderNumber: realOrder.orderNumber,
            ),
          ),
        );
      } catch (error) {
        if (!mounted) return;
        setState(() => _busy = false);
        _showError(error);
      }
    }
  }

  PaymentSession _transferSession(PaymentSession? payment, CustomerOrder? order) {
    if (payment != null && payment.awaitsTransfer) {
      final fields = payment.checkoutFields;
      final hasAccount =
          (fields['bankBin'] ?? '').isNotEmpty &&
          (fields['accountNumber'] ?? '').isNotEmpty;
      if (hasAccount) return payment;
      return PaymentSession(
        id: payment.id,
        orderId: payment.orderId,
        provider: payment.provider,
        method: payment.method,
        status: payment.status,
        amount: payment.amount,
        currencyCode: payment.currencyCode,
        providerReference: payment.providerReference,
        checkoutUrl: payment.checkoutUrl,
        checkoutFields: {
          ...fields,
          'bankCode': 'MB',
          'bankBin': _sandboxBankBin,
          'accountNumber': _sandboxAccountNumber,
          'accountHolderName': _sandboxAccountHolder,
        },
      );
    }
    final fields = {
      ...?payment?.checkoutFields,
      'bankCode': 'MB',
      'bankBin': _sandboxBankBin,
      'accountNumber': _sandboxAccountNumber,
      'accountHolderName': _sandboxAccountHolder,
      if (order != null) 'transferContent': order.orderNumber,
    };
    return PaymentSession(
      id: payment?.id ?? '',
      orderId: payment?.orderId ?? order?.id ?? '',
      provider: payment?.provider ?? 'SePay',
      method: PaymentMethod.bankTransfer.name,
      status: payment?.status ?? 'Pending',
      amount: payment?.currencyCode == 'VND'
          ? payment!.amount
          : _scanAmountVnd(_cart).toDouble(),
      currencyCode: 'VND',
      providerReference: payment?.providerReference,
      checkoutUrl: payment?.checkoutUrl,
      checkoutFields: fields,
    );
  }

  int _scanAmountVnd(Cart? cart) {
    final subtotal = cart?.subtotal ?? 0;
    if (cart?.currencyCode == 'VND') return subtotal.round();
    return (subtotal * _eurToVndRate).round();
  }

  String _sandboxQrUrl(int amountVnd) {
    return Uri.https(
      'img.vietqr.io',
      'image/$_sandboxBankBin-$_sandboxAccountNumber-compact2.png',
      {
        'accountName': _sandboxAccountHolder,
        'amount': '$amountVnd',
      },
    ).toString();
  }

  Future<PaymentSession> _waitForPayment(String orderId) async {
    PaymentSession? latest;
    for (var attempt = 0; attempt < 8; attempt++) {
      latest = await widget.api.latestPayment(orderId);
      if (latest.status == 'Succeeded' ||
          latest.status == 'Failed' ||
          latest.status == 'Cancelled') {
        return latest;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return latest!;
  }

  Future<void> _finishDisplayedTransfer(
    PaymentSession session,
    CustomerOrder? order,
  ) async {
    if (order != null) {
      try {
        final latest = await widget.api.latestPayment(order.id);
        if (!mounted) return;
        if (latest.status == 'Succeeded') {
          await _complete(latest);
          return;
        }
      } catch (_) {
        // The sandbox confirmation still finishes checkout.
      }
    }
    if (!mounted) return;
    await _complete(session);
  }

  Future<void> _complete(PaymentSession payment) async {
    final order = _order;
    if (order != null) {
      final session = await widget.api.loadSession();
      if (!mounted) return;
      ShipmentBoard.instance.track(
        order,
        customerName:
            session?.displayName ??
            _selectedAddress?.recipientName ??
            AppStrings.guest,
      );
    }
    if (!mounted) return;
    setState(() {
      _payment = payment;
      _awaitingConfirmation = false;
      _paymentError = null;
      _busy = false;
      _step = CheckoutStep.done;
    });
  }

  void _showError(Object error) {
    showAppErrorSnackBar(
      context,
      error,
      fallback: AppStrings.errorRequestFailed,
    );
  }

  void _selectAddress(CustomerAddress address) {
    setState(() {
      _selectedAddress = address;
      _latitude = address.latitude;
      _longitude = address.longitude;
      _contactControllers['label']!.text = address.label;
      _contactControllers['recipientName']!.text = address.recipientName;
      _contactControllers['phoneNumber']!.text = address.phoneNumber;
      _addressControllers['addressLine']!.text = address.addressLine;
      _addressControllers['city']!.text = address.city;
      _addressControllers['province']!.text = address.province ?? '';
      _addressControllers['postalCode']!.text = address.postalCode ?? '';
      _addressControllers['countryCode']!.text = address.countryCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.checkoutTitle),
        leading: IconButton(
          tooltip: AppStrings.cancel,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _busy && _cart == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _cart == null
          ? Center(child: Text(_error!))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                _buildStepper(theme),
                const SizedBox(height: AppSpacing.xl),
                switch (_step) {
                  CheckoutStep.contact => _buildContactStep(),
                  CheckoutStep.address => _buildAddressStep(),
                  CheckoutStep.payment => _buildPaymentStep(),
                  CheckoutStep.done => _buildDoneStep(),
                },
              ],
            ),
    );
  }

  Widget _buildStepper(ThemeData theme) => Row(
    children: [
      for (final step in CheckoutStep.values)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: step.index <= _step.index
                        ? AppColors.brand
                        : AppColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _stepLabel(step),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: step.index == _step.index
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: step.index <= _step.index
                        ? AppColors.brand
                        : AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );

  String _stepLabel(CheckoutStep step) => switch (step) {
    CheckoutStep.contact => AppStrings.stepContact,
    CheckoutStep.address => AppStrings.stepAddress,
    CheckoutStep.payment => AppStrings.stepPayment,
    CheckoutStep.done => AppStrings.stepDone,
  };

  Widget _sectionCard(Widget child) => Card(
    child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: child),
  );

  Widget _buildContactStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.useSavedContact, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        if (_addresses.isEmpty)
          _sectionCard(
            Text(AppStrings.noSavedContacts, style: theme.textTheme.bodyMedium),
          )
        else ...[
          RadioGroup<String>(
            groupValue: _selectedAddress?.id,
            onChanged: (id) {
              final address = _addresses
                  .where((item) => item.id == id)
                  .firstOrNull;
              if (address != null) _selectAddress(address);
            },
            child: Column(
              children: [
                for (final address in _addresses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _sectionCard(
                      RadioListTile<String>(
                        value: address.id,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          address.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${address.recipientName} · ${address.phoneNumber}\n'
                          '${address.fullAddress}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedAddress != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => setState(() => _step = CheckoutStep.address),
                icon: const Icon(Icons.arrow_forward),
                label: Text(
                  AppStrings.continueWithSelectedAddress(_selectedAddress!.label),
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.xl),
        _sectionCard(
          ExpansionTile(
            title: Text(
              _addresses.isEmpty ? AppStrings.newContact : AppStrings.orEnterNewAddress,
              style: theme.textTheme.titleMedium,
            ),
            initiallyExpanded: _addresses.isEmpty,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Form(
                key: _contactFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _contactControllers['label'],
                      decoration: InputDecoration(
                        labelText: AppStrings.fieldAddressLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _contactControllers['recipientName'],
                      decoration: InputDecoration(
                        labelText: AppStrings.fieldRecipientName,
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _contactControllers['phoneNumber'],
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: AppStrings.fieldPhoneNumber,
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _addressControllers['addressLine'],
                      decoration: InputDecoration(
                        labelText: AppStrings.fieldAddressLine,
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _addressControllers['city'],
                      decoration: InputDecoration(
                        labelText: AppStrings.fieldCity,
                      ),
                      validator: _requiredValidator,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _saveNewContact,
                  child: Text(
                    _busy ? AppStrings.pleaseWait : AppStrings.saveNewAddressAndContinue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _selectedAddress == null ? null : _openPaymentStep,
            icon: const Icon(Icons.arrow_forward),
            label: Text(AppStrings.stepPayment),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressStep() {
    final theme = Theme.of(context);
    final address = _selectedAddress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.deliveryAddressStep,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(AppStrings.dropPinHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.md),
        _sectionCard(
          MapPointPicker(
            initialLatitude: _latitude,
            initialLongitude: _longitude,
            onPointChanged: (latitude, longitude) => setState(() {
              _latitude = latitude;
              _longitude = longitude;
            }),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _sectionCard(
          Form(
            key: _addressFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _addressControllers['addressLine'],
                  decoration: InputDecoration(
                    labelText: AppStrings.fieldAddressLine,
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _addressControllers['city'],
                  decoration: InputDecoration(labelText: AppStrings.fieldCity),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _addressControllers['province'],
                        decoration: InputDecoration(
                          labelText: AppStrings.fieldProvince,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _addressControllers['postalCode'],
                        decoration: InputDecoration(
                          labelText: AppStrings.fieldPostalCode,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _addressControllers['countryCode'],
                  decoration: InputDecoration(
                    labelText: AppStrings.fieldCountryCode,
                  ),
                  validator: _requiredValidator,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy || address == null ? null : _saveDeliveryPoint,
            icon: const Icon(Icons.arrow_forward),
            label: Text(_busy ? AppStrings.pleaseWait : AppStrings.stepPayment),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    final theme = Theme.of(context);
    final cart = _cart;
    final address = _selectedAddress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 20, color: AppColors.brand),
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
            if (method == null) return;
            setState(() => _method = method);
          },
          child: Column(
            children: [
              for (final method in _offeredMethods)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _sectionCard(
                    RadioListTile<PaymentMethod>(
                      value: method,
                      contentPadding: EdgeInsets.zero,
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
        ),
        if (_method != PaymentMethod.cod) ...[
          const SizedBox(height: AppSpacing.md),
          _buildBankAccountCard(),
        ],
        const SizedBox(height: AppSpacing.md),
        _buildSummaryCard(cart, address),
        if (_paymentError != null) ...[
          const SizedBox(height: AppSpacing.md),
          _sectionCard(
            Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(_paymentError!)),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy ? null : _placeOrder,
            icon: const Icon(Icons.lock_outline),
            label: Text(
              _busy
                  ? AppStrings.processingPayment
                  : _awaitingConfirmation
                  ? AppStrings.checkPayment
                  : _order == null
                  ? AppStrings.placeOrder
                  : AppStrings.tryAgain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankAccountCard() {
    final theme = Theme.of(context);
    final amountVnd = _scanAmountVnd(_cart);
    return _sectionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.paymentBank, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Center(child: sandboxQrImage(_sandboxQrUrl(amountVnd))),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              formatPrice(amountVnd.toDouble(), 'VND'),
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Cart? cart, CustomerAddress? address) {
    final theme = Theme.of(context);
    final subtotal = cart?.subtotal ?? 0;
    final currency = cart?.currencyCode ?? 'EUR';
    final shipping = 0.0;
    return _sectionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.orderSummary, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final item in cart?.items ?? const <CartItem>[]) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${item.size} · ${item.color} · '
                        '${AppStrings.quantityShort} ${item.quantity}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(formatPrice(item.lineTotal, currency)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const Divider(height: AppSpacing.lg),
          _summaryRow(AppStrings.subtotal, formatPrice(subtotal, currency)),
          const SizedBox(height: AppSpacing.sm),
          _summaryRow(
            AppStrings.delivery,
            shipping == 0 ? AppStrings.free : formatPrice(shipping, currency),
          ),
          const SizedBox(height: AppSpacing.sm),
          _summaryRow(
            AppStrings.total,
            formatPrice(subtotal + shipping, currency),
            emphasise: true,
          ),
          if (address != null) ...[
            const Divider(height: AppSpacing.xl),
            Text(AppStrings.shippingTo, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(address.fullAddress),
            if (_latitude != null && _longitude != null)
              Text(
                '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool emphasise = false}) {
    final theme = Theme.of(context);
    final style = emphasise
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyMedium;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }

  Widget _buildDoneStep() {
    final theme = Theme.of(context);
    final order = _order;
    final payment = _payment;
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: const BoxDecoration(
            color: AppColors.brandSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size: 56,
            color: AppColors.brand,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          AppStrings.orderPlacedTitle,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _payment?.method == 'cod'
              ? AppStrings.orderPlacedCodBody
              : AppStrings.orderPlacedBody,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (order != null)
          _sectionCard(
            Column(
              children: [
                _summaryRow(AppStrings.ordersTitle, order.orderNumber),
                const SizedBox(height: AppSpacing.sm),
                _summaryRow(
                  AppStrings.total,
                  formatPrice(order.totalAmount, order.currencyCode),
                ),
                if (payment?.providerReference != null &&
                    payment!.providerReference!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _summaryRow(
                    AppStrings.paymentReference,
                    payment.providerReference!,
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: order == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          OrderDetailPage(api: widget.api, order: order),
                    ),
                  ),
            icon: const Icon(Icons.local_shipping_outlined),
            label: Text(AppStrings.trackOrder),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: Text(AppStrings.continueShopping),
          ),
        ),
      ],
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

  String? _requiredValidator(String? value) =>
      (value == null || value.trim().isEmpty) ? AppStrings.required : null;
}
