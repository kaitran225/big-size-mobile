import 'package:flutter/material.dart';

import 'app/bigfit_app.dart';
import 'services/store_api.dart';

void main() {
  runApp(BigFitApp(api: StoreApi()));
}
