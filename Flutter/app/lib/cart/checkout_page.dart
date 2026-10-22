import 'package:flutter/material.dart';

import '../auth/auth_sheet.dart';
import '../models/checkout_models.dart';
import '../models/store_product.dart';
import '../orders/order_detail_page.dart';
import '../payment/sandbox_gateway.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/app_snack_bar.dart';
import '../map/map_point_picker.dart';

/// Checkout flow: contact, delivery address, sandbox payment and confirmation.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.api});

  final StoreApi api;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const SandboxGateway _gateway = SandboxGateway();

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
  bool _useNewContact = false;
  double? _latitude;
  double? _longitude;
  PaymentMethod _method = PaymentMethod.cod;
  bool _decline = false;
  bool _busy = false;
  String? _error;
  CustomerOrder? _order;
  SandboxPaymentResult? _payment;

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
        _selectedAddress = _addresses.where((a) => a.isDefault).firstOrNull ??
            _addresses.firstOrNull;
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
        _useNewContact = false;
        _busy = false;
        _step = CheckoutStep.address;
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
      final saved = await widget.api.saveAddress(
        {
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
        },
        id: address.id,
      );
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

  Future<void> _placeOrder() async {
    final address = _selectedAddress;
    final cart = _cart;
    if (address == null || cart == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await widget.api.createOrder(
        shippingAddressId: address.id,
      );
      if (!mounted) return;
      setState(() {
        _order = order;
        _busy = false;
        _step = CheckoutStep.payment;
      });

      final result = await _gateway.charge(
        method: _method,
        amount: order.totalAmount,
        currencyCode: order.currencyCode,
        decline: _decline,
      );
      if (!mounted) return;
      setState(() {
        _payment = result;
        _busy = false;
        _step = result.approved ? CheckoutStep.done : CheckoutStep.payment;
      });
      if (!result.approved) {
        showAppSnackBar(context, AppStrings.paymentDeclinedTitle);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError(error);
    }
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
      _useNewContact = false;
      _latitude = address.latitude;
      _longitude = address.longitude;
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
        title: const Text(AppStrings.checkoutTitle),
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
            Text(
              AppStrings.noSavedContacts,
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          ..._addresses.map(
            (address) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _sectionCard(
                RadioListTile<String>(
                  value: address.id,
                  groupValue: _selectedAddress?.id,
                  onChanged: (_) => _selectAddress(address),
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
          ),
        const SizedBox(height: AppSpacing.sm),
        _sectionCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.newContact, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              Form(
                key: _contactFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _contactControllers['label'],
                      decoration: const InputDecoration(
                        labelText: AppStrings.fieldAddressLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _contactControllers['recipientName'],
                      decoration: const InputDecoration(
                        labelText: AppStrings.fieldRecipientName,
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _contactControllers['phoneNumber'],
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: AppStrings.fieldPhoneNumber,
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _addressControllers['addressLine'],
                      decoration: const InputDecoration(
                        labelText: AppStrings.fieldAddressLine,
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _addressControllers['city'],
                      decoration: const InputDecoration(
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
                    _busy ? AppStrings.pleaseWait : AppStrings.saveAndContinue,
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
            onPressed: _selectedAddress == null
                ? null
                : () => setState(() => _step = CheckoutStep.address),
            icon: const Icon(Icons.arrow_forward),
            label: const Text(AppStrings.stepAddress),
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
        Text(AppStrings.deliveryAddressStep, style: theme.textTheme.titleMedium),
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
                  decoration: const InputDecoration(
                    labelText: AppStrings.fieldAddressLine,
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _addressControllers['city'],
                  decoration: const InputDecoration(
                    labelText: AppStrings.fieldCity,
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _addressControllers['province'],
                        decoration: const InputDecoration(
                          labelText: AppStrings.fieldProvince,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _addressControllers['postalCode'],
                        decoration: const InputDecoration(
                          labelText: AppStrings.fieldPostalCode,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _addressControllers['countryCode'],
                  decoration: const InputDecoration(
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
            label: Text(
              _busy ? AppStrings.pleaseWait : AppStrings.stepPayment,
            ),
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
              const Icon(
                Icons.science_outlined,
                size: 20,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.sandboxBanner,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.accent,
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
        ...PaymentMethod.values.map(
          (method) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _sectionCard(
              RadioListTile<PaymentMethod>(
                value: method,
                groupValue: _method,
                onChanged: (value) => setState(() => _method = value ?? _method),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _methodLabel(method),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(_methodNote(method)),
              ),
            ),
          ),
        ),
        SwitchListTile(
          value: _decline,
          onChanged: (value) => setState(() => _decline = value),
          title: Text(
            AppStrings.simulateFailure,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildSummaryCard(cart, address),
        if (_payment != null && !_payment!.approved) ...[
          const SizedBox(height: AppSpacing.md),
          _sectionCard(
            Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(_payment!.message)),
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
              _busy ? AppStrings.processingPayment : AppStrings.placeOrder,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(Cart? cart, CustomerAddress? address) {
    final theme = Theme.of(context);
    final subtotal = cart?.subtotal ?? 0;
    final currency = cart?.currencyCode ?? 'EUR';
    final shipping = cart == null || cart.items.isEmpty ? 0.0 : 4.9;
    return _sectionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.orderSummary, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
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
            Text(
              AppStrings.shippingTo,
              style: theme.textTheme.labelLarge,
            ),
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
          AppStrings.orderPlacedBody,
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
                if (payment != null && payment.reference.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _summaryRow(AppStrings.paymentReference, payment.reference),
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
                      builder: (_) => OrderDetailPage(
                        api: widget.api,
                        order: order,
                      ),
                    ),
                  ),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text(AppStrings.trackOrder),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text(AppStrings.continueShopping),
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
