/// The stages a shopper moves through while checking out.
enum CheckoutStep { contact, address, payment, done }

/// Payment methods offered by the sandbox gateway.
enum PaymentMethod { cod, bankTransfer, gateway }

/// One stage of the shipment tracker, in delivery order.
enum ShipmentStage {
  placed,
  confirmed,
  packed,
  shipped,
  outForDelivery,
  delivered,
}

/// A shipment record shared by the customer tracker and the staff board.
class Shipment {
  const Shipment({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.stage,
    required this.courier,
    required this.trackingNumber,
    required this.updatedAt,
    required this.itemCount,
  });

  final String id;
  final String orderNumber;
  final String customerName;
  final ShipmentStage stage;
  final String courier;
  final String trackingNumber;
  final DateTime updatedAt;
  final int itemCount;

  bool get isDelivered => stage == ShipmentStage.delivered;

  Shipment copyWith({ShipmentStage? stage, DateTime? updatedAt}) => Shipment(
    id: id,
    orderNumber: orderNumber,
    customerName: customerName,
    stage: stage ?? this.stage,
    courier: courier,
    trackingNumber: trackingNumber,
    updatedAt: updatedAt ?? this.updatedAt,
    itemCount: itemCount,
  );
}

/// The outcome of a sandbox payment attempt.
class SandboxPaymentResult {
  const SandboxPaymentResult({
    required this.approved,
    required this.reference,
    required this.message,
  });

  final bool approved;
  final String reference;
  final String message;
}
