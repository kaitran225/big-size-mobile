import 'package:flutter/material.dart';

import '../shared/app_strings.dart';
import '../shared/widgets/not_implemented_view.dart';

/// Placeholder for the review moderation screen.
class AdminReviewsPage extends StatelessWidget {
  const AdminReviewsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.customerReviews)),
        body: const NotImplementedView(title: AppStrings.customerReviews),
      );
}
