import 'package:flutter/material.dart';

import 'app/bigfit_app.dart';
import 'services/store_api.dart';
import 'shared/app_strings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStrings.initialize();
  final api = StoreApi();
  await api.loadSavedBaseUrl();
  runApp(BigFitApp(api: api));
}
