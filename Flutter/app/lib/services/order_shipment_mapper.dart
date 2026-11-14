import '../models/checkout_models.dart';
import '../models/store_product.dart';

/// Maps API order status strings onto shipment tracker stages.
abstract final class OrderShipmentMapper {
  static ShipmentStage stageForStatus(String status) => switch (
    status.toLowerCase()
  ) {
    'confirmed' => ShipmentStage.confirmed,
    'processing' => ShipmentStage.packed,
    'shipped' => ShipmentStage.shipped,
    'outfordelivery' => ShipmentStage.outForDelivery,
    'delivered' => ShipmentStage.delivered,
    _ => ShipmentStage.placed,
  };

  static Shipment shipmentForOrder(CustomerOrder order, {String? customerName}) {
    final stamp = order.id.replaceAll('-', '').padRight(8, '0').substring(0, 8);
    return Shipment(
      id: order.id,
      orderNumber: order.orderNumber,
      customerName: customerName ?? '',
      stage: stageForStatus(order.status),
      courier: 'BigFit Express',
      trackingNumber: 'BF${stamp.toUpperCase()}',
      updatedAt: order.updatedAt,
      itemCount: order.items.length,
    );
  }

  static String? nextFulfillmentAction(String status) => switch (
    status.toLowerCase()
  ) {
    'pending' || 'confirmed' => 'accept',
    'processing' => 'ship',
    'shipped' => 'complete',
    _ => null,
  };
}
