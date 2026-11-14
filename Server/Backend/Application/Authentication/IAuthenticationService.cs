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

    /// <summary>Updates one account. Returns null when the account does not exist.</summary>
    Task<UserAccountResponse?> UpdateUserAsync(
        Guid userId,
        UpdateUserRequest request,
        Guid currentUserId,
        CancellationToken cancellationToken);

    /// <summary>Deletes one account. Returns false when the account does not exist.</summary>
    Task<bool> DeleteUserAsync(
        Guid userId,
        Guid currentUserId,
        CancellationToken cancellationToken);
}
