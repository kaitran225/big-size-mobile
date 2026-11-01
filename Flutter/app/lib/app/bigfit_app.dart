import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../catalog/storefront_page.dart';
import '../services/store_api.dart';
import '../shared/app_strings.dart';
import '../shared/theme/app_theme.dart';

class BigFitApp extends StatelessWidget {
  const BigFitApp({super.key, required this.api});

  final StoreApi api;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AppLanguage>(
    valueListenable: AppStrings.language,
    builder: (context, language, _) => MaterialApp(
      title: AppStrings.appTitle,
      locale: Locale(language == AppLanguage.vietnamese ? 'vi' : 'en'),
      supportedLocales: const [Locale('en'), Locale('vi')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: StorefrontPage(api: api),
    ),
  );
}
