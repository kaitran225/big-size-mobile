import 'package:app/models/checkout_models.dart';
import 'package:app/models/store_product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('staff order payment state gates fulfillment actions', () {
    final pendingTransfer = StaffFulfillmentOrder.fromJson({
      'id': 'order-1',
      'orderNumber': 'BF-1',
      'status': 'Pending',
      'totalAmount': 50,
      'currencyCode': 'EUR',
      'customerDisplayName': 'Customer',
      'customerEmail': 'customer@example.com',
      'paymentMethod': 'bankTransfer',
      'paymentStatus': 'Pending',
      'items': [],
      'updatedAt': '2026-01-01T00:00:00Z',
      'rejectionReason': null,
    });

    expect(pendingTransfer.awaitingBankConfirmation, isTrue);
    expect(pendingTransfer.canAccept, isFalse);
    expect(pendingTransfer.canReject, isTrue);

    final paidTransfer = StaffFulfillmentOrder.fromJson({
      'id': 'order-2',
      'orderNumber': 'BF-2',
      'status': 'Pending',
      'totalAmount': 50,
      'currencyCode': 'EUR',
      'customerDisplayName': 'Customer',
      'customerEmail': 'customer@example.com',
      'paymentMethod': 'bankTransfer',
      'paymentStatus': 'Succeeded',
      'items': [],
      'updatedAt': '2026-01-01T00:00:00Z',
      'rejectionReason': null,
    });

    expect(paidTransfer.canAccept, isTrue);
    expect(paidTransfer.canReject, isFalse);
  });

  test('customer order exposes the staff rejection reason', () {
    final order = CustomerOrder.fromJson({
      'id': 'order-1',
      'orderNumber': 'BF-1',
      'status': 'Cancelled',
      'subtotal': 50,
      'shippingAmount': 0,
      'totalAmount': 50,
      'currencyCode': 'EUR',
      'rejectionReason': 'Item is no longer available',
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-02T00:00:00Z',
      'items': [],
    });

    expect(order.rejectionReason, 'Item is no longer available');
  });
}
