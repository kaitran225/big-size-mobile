import 'package:flutter/material.dart';

import '../shared/app_strings.dart';
import '../shared/widgets/not_implemented_view.dart';

/// Placeholder for the customer review list and form.
class CustomerReviewsPage extends StatelessWidget {
  const CustomerReviewsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.myReviews)),
        body: const NotImplementedView(title: AppStrings.myReviews),
      );
}
