import 'package:flutter/material.dart';

import '../models/checkout_models.dart';
import '../orders/delivery_tracking_map.dart';
import '../orders/order_tracker.dart';
import '../services/order_shipment_mapper.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/formatters.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/app_snack_bar.dart';

/// Staff review of one order before it is accepted or rejected.
class StaffOrderReviewPage extends StatefulWidget {
  const StaffOrderReviewPage({super.key, required this.api, required this.order});

  final StoreApi api;
  final StaffFulfillmentOrder order;

  @override
  State<StaffOrderReviewPage> createState() => _StaffOrderReviewPageState();
}

class _StaffOrderReviewPageState extends State<StaffOrderReviewPage> {
  bool _busy = false;
  String? _error;

  StaffFulfillmentOrder get _order => widget.order;

  String? get _nextAction =>
      OrderShipmentMapper.nextFulfillmentAction(_order.status);

  String get _nextActionLabel {
    if (_order.awaitingBankConfirmation) {
      return AppStrings.fulfillmentWaitingForPayment;
    }
    return switch (_nextAction) {
      'accept' => AppStrings.fulfillmentAccept,
      'ship' => AppStrings.fulfillmentShip,
      'complete' => AppStrings.fulfillmentComplete,
      _ => AppStrings.advanceStatus,
    };
  }

  Future<void> _apply(String action, {String? reason}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.applyFulfillmentAction(
        orderId: _order.id,
        action: action,
        reason: reason,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = appErrorMessage(error, fallback: AppStrings.errorRequestFailed);
      });
    }
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.rejectionDialogTitle),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 500,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: AppStrings.rejectionReasonLabel,
              hintText: AppStrings.rejectionReasonHint,
              alignLabelWithHint: true,
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return AppStrings.rejectionReasonRequired;
              if (text.length > 500) return AppStrings.rejectionReasonTooLong;
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: Text(AppStrings.confirmRejection),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;
    await _apply('reject', reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = _order.shippingAddress;
    final action = _nextAction;
    final canAdvance = action != null && !(action == 'accept' && !_order.canAccept);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.orderReviewTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _order.orderNumber,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Chip(label: Text(AppStrings.orderStatus(_order.status))),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(AppStrings.reviewNote, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.customerLabel, style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(_order.customerName),
                Text(_order.customerEmail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.paymentTitle, style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  '${_order.paymentMethod ?? '-'} · '
                  '${_order.paymentStatus ?? '-'}',
                ),
                if (_order.awaitingBankConfirmation) ...[
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.fulfillmentPaymentPending,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.orderItems, style: theme.textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                for (final item in _order.items) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName),
                            Text(
                              '${item.size} · ${item.color} · '
                              '${AppStrings.quantityShort} ${item.quantity}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(formatPrice(item.lineTotal, _order.currencyCode)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const Divider(),
                _row(
                  AppStrings.subtotal,
                  formatPrice(_order.totalAmount, _order.currencyCode),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.deliveryAddressTitle,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (address == null)
                  Text(AppStrings.noSavedContact)
                else ...[
                  if ((address.recipientName ?? '').isNotEmpty)
                    Text(
                      address.recipientName!,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  if ((address.phoneNumber ?? '').isNotEmpty)
                    Text(address.phoneNumber!),
                  const SizedBox(height: 4),
                  Text(address.formatted),
                  if (address.hasCoordinates) ...[
                    const SizedBox(height: AppSpacing.md),
                    DeliveryTrackingMap(
                      stage: OrderShipmentMapper.stageForStatus(_order.status),
                      destinationLatitude: address.latitude,
                      destinationLongitude: address.longitude,
                      height: 220,
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        AppStrings.noMapPoint,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.shipmentTracking,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                ShipmentTracker(
                  stage: OrderShipmentMapper.stageForStatus(_order.status),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: _busy || !canAdvance ? null : () => _apply(action),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(_busy ? AppStrings.pleaseWait : _nextActionLabel),
          ),
          if (_order.canReject) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _busy ? null : _reject,
              icon: const Icon(Icons.block_outlined),
              label: Text(AppStrings.fulfillmentReject),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card(Widget child) => Card(
    child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: child),
  );

  Widget _row(String label, String value) => Row(
    children: [
      Expanded(child: Text(label)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}
