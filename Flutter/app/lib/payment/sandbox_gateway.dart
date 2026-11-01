import '../models/checkout_models.dart';
import '../shared/app_strings.dart';

/// A local stand-in for a payment provider sandbox.
///
/// The real gateway is not connected yet, so the checkout runs against this
/// class: it takes a moment to answer and can be told to decline so both the
/// success and the failure path can be demonstrated.
class SandboxGateway {
  const SandboxGateway({this.processingDelay = const Duration(seconds: 2)});

  final Duration processingDelay;

  Future<SandboxPaymentResult> charge({
    required PaymentMethod method,
    required double amount,
    required String currencyCode,
    bool decline = false,
  }) async {
    await Future<void>.delayed(processingDelay);

    if (decline) {
      return SandboxPaymentResult(
        approved: false,
        reference: '',
        message: AppStrings.sandboxPaymentDeclined,
      );
    }

    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return SandboxPaymentResult(
      approved: true,
      reference: 'SBX-${stamp.toUpperCase()}',
      message: AppStrings.approvedSandboxPayment(
        AppStrings.paymentMethodName(method.name),
        amount.toStringAsFixed(2),
        currencyCode,
      ),
    );
  }
}
