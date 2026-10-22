import '../services/store_api.dart';
import 'app_strings.dart';

/// Symbols rendered next to a price for the currencies BigFit sells in.
const Map<String, String> currencySymbols = {
  'EUR': '€',
  'USD': '\$',
  'VND': '₫',
};

/// Currency displayed without decimal places.
const String zeroDecimalCurrency = 'VND';

String displayError(Object error) =>
    error is StoreApiException ? error.message : AppStrings.errorRequestFailed;

String formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String currencySymbol(String currencyCode) =>
    currencySymbols[currencyCode] ?? '$currencyCode ';

String formatPrice(double amount, String currencyCode) {
  final symbol = currencySymbol(currencyCode);
  final decimals = currencyCode == zeroDecimalCurrency ? 0 : 2;
  return '$symbol${amount.toStringAsFixed(decimals)}';
}
