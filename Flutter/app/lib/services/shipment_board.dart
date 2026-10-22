import 'dart:math';

import '../models/checkout_models.dart';
import '../models/store_product.dart';

/// In-memory shipment board shared by the customer tracker and the staff view.
///
/// The backend does not expose a shipment endpoint yet, so shipment states are
/// held on the device for the demo. Orders placed during the session register
/// themselves so staff can advance them and the customer sees the update.
class ShipmentBoard {
  ShipmentBoard._();

  static final ShipmentBoard instance = ShipmentBoard._();

  static const List<String> _couriers = [
    'BigFit Express',
    'Giao Hang Nhanh',
    'J&T Express',
  ];

  final Map<String, Shipment> _shipments = {};
  final Random _random = Random();

  List<Shipment> get shipments {
    final values = _shipments.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return values;
  }

  /// Registers an order on the board and returns its shipment record.
  Shipment track(CustomerOrder order, {String customerName = 'BigFit customer'}) {
    return _shipments.putIfAbsent(order.id, () {
      final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      return Shipment(
        id: order.id,
        orderNumber: order.orderNumber,
        customerName: customerName,
        stage: stageForStatus(order.status),
        courier: _couriers[_random.nextInt(_couriers.length)],
        trackingNumber: 'BF${stamp.toUpperCase()}',
        updatedAt: DateTime.now(),
        itemCount: order.items.length,
      );
    });
  }

  /// Moves a shipment one stage forward.
  Shipment advance(Shipment shipment) {
    final nextIndex = shipment.stage.index + 1;
    if (nextIndex >= ShipmentStage.values.length) return shipment;
    final updated = shipment.copyWith(
      stage: ShipmentStage.values[nextIndex],
      updatedAt: DateTime.now(),
    );
    _shipments[shipment.id] = updated;
    return updated;
  }

  /// Maps an order status onto the matching shipment stage.
  ShipmentStage stageForStatus(String status) => switch (status.toLowerCase()) {
    'confirmed' => ShipmentStage.confirmed,
    'processing' => ShipmentStage.packed,
    'shipped' => ShipmentStage.outForDelivery,
    'delivered' => ShipmentStage.delivered,
    _ => ShipmentStage.placed,
  };
}
