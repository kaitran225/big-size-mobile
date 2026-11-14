using BigFit.Application.Catalog;

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

    /// <summary>Lists accounts with their roles for the administrator console.</summary>
    Task<PagedResponse<UserAccountResponse>> GetUsersAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken cancellationToken);
}
