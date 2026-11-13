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

/// The linked SePay sandbox account shown during checkout.
class LinkedBankAccount {
  const LinkedBankAccount({
    required this.bankCode,
    required this.bankBin,
    required this.accountNumber,
    required this.accountHolderName,
  });

  final String bankCode;
  final String bankBin;
  final String accountNumber;
  final String accountHolderName;

  factory LinkedBankAccount.fromJson(Map<String, dynamic> json) =>
      LinkedBankAccount(
        bankCode: json['bankCode'] as String? ?? '',
        bankBin: json['bankBin'] as String? ?? '',
        accountNumber: json['accountNumber'] as String? ?? '',
        accountHolderName: json['accountHolderName'] as String? ?? '',
      );
}

/// A payment attempt returned by the BigFit API.
class PaymentSession {
  const PaymentSession({
    required this.id,
    required this.orderId,
    required this.provider,
    required this.method,
    required this.status,
    required this.amount,
    required this.currencyCode,
    this.providerReference,
    this.checkoutUrl,
    this.checkoutFields = const {},
  });

  final String id;
  final String orderId;
  final String provider;
  final String method;
  final String status;
  final double amount;
  final String currencyCode;
  final String? providerReference;
  final String? checkoutUrl;
  final Map<String, String> checkoutFields;

  bool get awaitsTransfer =>
      checkoutFields['transferContent']?.isNotEmpty == true;

  factory PaymentSession.fromJson(Map<String, dynamic> json) {
    final rawFields = json['checkoutFields'];
    final fields = <String, String>{};
    if (rawFields is Map) {
      for (final entry in rawFields.entries) {
        fields['${entry.key}'] = '${entry.value}';
      }
    }
    return PaymentSession(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      provider: json['provider'] as String,
      method: json['method'] as String,
      status: json['status'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String,
      providerReference: json['providerReference'] as String?,
      checkoutUrl: json['checkoutUrl'] as String?,
      checkoutFields: fields,
    );
  }
}

/// Order row on the staff fulfilment queue.
class StaffFulfillmentOrder {
  const StaffFulfillmentOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.currencyCode,
    required this.customerName,
    required this.customerEmail,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.itemCount,
    required this.updatedAt,
    required this.rejectionReason,
  });

  final String id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final String currencyCode;
  final String customerName;
  final String customerEmail;
  final String? paymentMethod;
  final String? paymentStatus;
  final int itemCount;
  final DateTime updatedAt;
  final String? rejectionReason;

  factory StaffFulfillmentOrder.fromJson(Map<String, dynamic> json) =>
      StaffFulfillmentOrder(
        id: json['id'] as String,
        orderNumber: json['orderNumber'] as String,
        status: json['status'] as String,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        currencyCode: json['currencyCode'] as String,
        customerName: json['customerDisplayName'] as String,
        customerEmail: json['customerEmail'] as String,
        paymentMethod: json['paymentMethod'] as String?,
        paymentStatus: json['paymentStatus'] as String?,
        itemCount: (json['items'] as List<dynamic>).length,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        rejectionReason: json['rejectionReason'] as String?,
      );

  bool get isDelivered => status.toLowerCase() == 'delivered';
  bool get canAccept =>
      status == 'Confirmed' ||
      (status == 'Pending' &&
          ((paymentMethod == 'cod' && paymentStatus == 'Pending') ||
              (paymentMethod == 'bankTransfer' &&
                  paymentStatus == 'Succeeded')));
  bool get canReject =>
      status == 'Pending' && paymentStatus != 'Succeeded';
  bool get awaitingBankConfirmation =>
      paymentMethod == 'bankTransfer' && paymentStatus == 'Pending';
}
