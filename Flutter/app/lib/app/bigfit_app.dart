import 'package:flutter/material.dart';

import '../catalog/storefront_page.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/theme/app_theme.dart';

class BigFitApp extends StatelessWidget {
  const BigFitApp({super.key, required this.api});

  final StoreApi api;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: AppStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: StorefrontPage(api: api),
      );
}
