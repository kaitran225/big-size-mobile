namespace BigFit.Application.Abstractions;

/// <summary>Extension point for future cart, favorites, and order use cases.</summary>
public interface IShoppingService;

/// <summary>Provider-neutral extension point for payment initiation and callbacks.</summary>
public interface IPaymentService;

/// <summary>Extension point for in-app and push notification use cases.</summary>
public interface INotificationService;

/// <summary>Provider-neutral extension point for BigFit product and size assistance.</summary>
public interface IChatAssistantService;

/// <summary>Extension point for email verification and password-reset delivery.</summary>
public interface IEmailVerificationService;

/// <summary>Extension point for expiring, rate-limited one-time codes.</summary>
public interface IOtpService;

/// <summary>Extension point for delivery addresses and map-provider integration.</summary>
public interface IMapLocationService;
