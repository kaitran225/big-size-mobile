import 'package:flutter/material.dart';

import '../../services/store_api.dart';
import '../formatters.dart';

/// Snack bar used for every transient message in the app.
class AppSnackBar extends SnackBar {
  AppSnackBar({super.key, required String message, super.behavior})
    : super(content: Text(message));
}

/// Shows [message] in a snack bar.
void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackBarBehavior? behavior,
}) {
  ScaffoldMessenger.of(context)
      .showSnackBar(AppSnackBar(message: message, behavior: behavior));
}

/// The message shown for [error]: the server detail for a
/// [StoreApiException], otherwise [fallback] or the generic error text.
String appErrorMessage(Object error, {String? fallback}) =>
    error is StoreApiException
    ? error.message
    : fallback ?? displayError(error);

/// Shows the message of [error] in a snack bar.
void showAppErrorSnackBar(
  BuildContext context,
  Object error, {
  String? fallback,
}) {
  showAppSnackBar(context, appErrorMessage(error, fallback: fallback));
}
