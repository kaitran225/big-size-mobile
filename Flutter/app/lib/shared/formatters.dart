import '../services/store_api.dart';

String displayError(Object error) => error is StoreApiException
    ? error.message
    : 'Could not complete the request. Please try again.';

String formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String formatPrice(double amount, String currencyCode) {
  final symbol = switch (currencyCode) {
    'EUR' => '€',
    'USD' => '\$',
    'VND' => '₫',
    _ => '$currencyCode ',
  };
  final decimals = currencyCode == 'VND' ? 0 : 2;
  return '$symbol${amount.toStringAsFixed(decimals)}';
}
