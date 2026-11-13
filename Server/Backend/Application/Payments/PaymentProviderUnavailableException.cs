namespace BigFit.Application.Payments;

public sealed class PaymentProviderUnavailableException(
    string message,
    Exception? innerException = null) : Exception(message, innerException);
