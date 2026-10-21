namespace BigFit.Application.Abstractions;

public sealed class DataConflictException(string message, Exception? innerException = null)
    : Exception(message, innerException);
