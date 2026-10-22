import 'package:flutter/material.dart';

import '../catalog/storefront_page.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';

class BigFitApp extends StatelessWidget {
  const BigFitApp({super.key, required this.api});

  final StoreApi api;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: AppStrings.appTitle,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF174C3C),
        surface: const Color(0xFFF8F7F3),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F7F3),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F7F3),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    home: StorefrontPage(api: api),
  );
}
