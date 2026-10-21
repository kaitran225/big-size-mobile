namespace BigFit.Application.Authentication;

public interface IAuthenticationService
{
    Task<AuthResponse> RegisterCustomerAsync(
        RegisterCustomerRequest request,
        CancellationToken cancellationToken);
    Task<AuthResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken);
    Task<UserResponse> CreateStoreStaffAsync(
        CreateStoreStaffRequest request,
        CancellationToken cancellationToken);
}
