import 'package:flutter/material.dart';

import '../shared/app_strings.dart';
import '../shared/widgets/not_implemented_view.dart';

/// Placeholder for the order fulfilment management screen.
class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.ordersTitle)),
        body: const NotImplementedView(title: AppStrings.ordersTitle),
      );
}
