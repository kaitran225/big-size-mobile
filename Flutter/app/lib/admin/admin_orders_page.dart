import 'package:flutter/material.dart';

import '../services/store_api.dart';
import '../staff/shipment_board_page.dart';

/// Staff order fulfilment entry point from admin tools.
class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key, required this.api});

  final StoreApi api;

  @override
  Widget build(BuildContext context) => ShipmentBoardPage(api: api);
}
