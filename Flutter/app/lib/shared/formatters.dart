import '../services/store_api.dart';
import 'app_strings.dart';

String displayError(Object error) =>
    error is StoreApiException ? error.message : AppStrings.errorGeneric;

String formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String formatPrice(double amount, String currencyCode) {
  final symbol = AppStrings.currencySymbol(currencyCode);
  final decimals = currencyCode == AppStrings.zeroDecimalCurrency ? 0 : 2;
  return '$symbol${amount.toStringAsFixed(decimals)}';
}
