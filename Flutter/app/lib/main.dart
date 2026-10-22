import 'package:flutter/material.dart';

import 'app/bigfit_app.dart';
import 'services/store_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = StoreApi();
  await api.loadSavedBaseUrl();
  runApp(BigFitApp(api: api));
}
