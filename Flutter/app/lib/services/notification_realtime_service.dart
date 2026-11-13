import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../models/store_product.dart';

class OrderStatusEvent {
  const OrderStatusEvent({
    required this.orderId,
    required this.status,
    required this.updatedAt,
  });

  final String orderId;
  final String status;
  final DateTime updatedAt;

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) => OrderStatusEvent(
    orderId: json['orderId'] as String,
    status: json['status'] as String,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

/// Live notification and order events from the BigFit SignalR hub.
class NotificationRealtimeService {
  HubConnection? _connection;
  final ValueNotifier<bool> connected = ValueNotifier(false);
  final ValueNotifier<StoreNotification?> notificationCreated = ValueNotifier(null);
  final ValueNotifier<OrderStatusEvent?> orderStatusChanged = ValueNotifier(null);
  final ValueNotifier<int> staffQueueTick = ValueNotifier(0);

  Future<void> connect({
    required Uri apiBaseUri,
    required String accessToken,
    required List<String> roles,
  }) async {
    await disconnect();
    final hubUrl =
        '${apiBaseUri.scheme}://${apiBaseUri.authority}/hubs/notifications'
        '?access_token=${Uri.encodeComponent(accessToken)}';
    final connection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            transport: HttpTransportType.WebSockets,
            skipNegotiation: false,
          ),
        )
        .withAutomaticReconnect()
        .build();

    connection.on('notificationCreated', (arguments) {
      final payload = arguments?.firstOrNull;
      if (payload is Map) {
        final map = payload.map(
          (key, value) => MapEntry('$key', value),
        );
        notificationCreated.value = StoreNotification.fromJson(
          Map<String, dynamic>.from(map),
        );
      }
    });

    connection.on('newOrder', (_) {
      staffQueueTick.value++;
    });

    connection.on('orderStatusChanged', (arguments) {
      final payload = arguments?.firstOrNull;
      if (payload is Map) {
        orderStatusChanged.value = OrderStatusEvent.fromJson(
          Map<String, dynamic>.from(
            payload.map((key, value) => MapEntry('$key', value)),
          ),
        );
      }
    });

    connection.onclose(({error}) {
      connected.value = false;
    });

    connection.onreconnected(({connectionId}) {
      connected.value = true;
    });

    _connection = connection;
    try {
      await connection.start();
      connected.value = true;
      final isStaff = roles.any((role) {
        final normalized = role.toLowerCase();
        return normalized.contains('admin') || normalized.contains('staff');
      });
      if (isStaff) {
        await connection.invoke('SubscribeStaff');
      }
    } catch (error) {
      connected.value = false;
      if (kDebugMode) {
        debugPrint('SignalR connect failed: $error');
      }
    }
  }

  Future<void> disconnect() async {
    connected.value = false;
    final connection = _connection;
    _connection = null;
    if (connection != null) {
      try {
        await connection.stop();
      } catch (_) {}
    }
  }
}
