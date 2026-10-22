import 'package:flutter/material.dart';

import '../shared/app_strings.dart';
import '../shared/widgets/not_implemented_view.dart';

/// Placeholder for the delivery map picker, which needs a Maps SDK key.
class DeliveryMapPage extends StatelessWidget {
  const DeliveryMapPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.mapTitle)),
        body: const NotImplementedView(title: AppStrings.mapTitle),
      );
}
