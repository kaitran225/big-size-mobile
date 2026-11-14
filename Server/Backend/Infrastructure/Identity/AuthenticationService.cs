using BigFit.Application.Abstractions;
using BigFit.Application.Authentication;
using BigFit.Application.Catalog;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace BigFit.Infrastructure.Identity;

internal sealed class AuthenticationService(
    UserManager<ApplicationUser> userManager,
    SignInManager<ApplicationUser> signInManager,
    JwtTokenIssuer tokenIssuer) : IAuthenticationService
{
    public async Task<AuthResponse> RegisterCustomerAsync(
        RegisterCustomerRequest request,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var user = new ApplicationUser
        {
            Id = Guid.NewGuid(),
            UserName = request.Email.Trim(),
            Email = request.Email.Trim(),
            DisplayName = request.DisplayName.Trim()
        };
        var creation = await userManager.CreateAsync(user, request.Password);
        EnsureSuccess(creation);

        var roleResult = await userManager.AddToRoleAsync(user, ApplicationRoles.Customer);
        if (!roleResult.Succeeded)
        {
            await RollbackUserCreationAsync(user);
            EnsureSuccess(roleResult);
        }

        return await CreateAuthResponseAsync(user);
    }

    public async Task<AuthResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var user = await userManager.FindByEmailAsync(request.Email.Trim());
        if (user is null || !await signInManager.CanSignInAsync(user))
        {
            return null;
        }

        var result = await signInManager.CheckPasswordSignInAsync(user, request.Password, lockoutOnFailure: true);
        return result.Succeeded ? await CreateAuthResponseAsync(user) : null;
    }

    public async Task<UserResponse> CreateStoreStaffAsync(
        CreateStoreStaffRequest request,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var user = new ApplicationUser
        {
            Id = Guid.NewGuid(),
            UserName = request.Email.Trim(),
            Email = request.Email.Trim(),
            DisplayName = request.DisplayName.Trim()
        };
        var creation = await userManager.CreateAsync(user, request.TemporaryPassword);
        EnsureSuccess(creation);

        var roleResult = await userManager.AddToRoleAsync(user, ApplicationRoles.StoreStaff);
        if (!roleResult.Succeeded)
        {
            await RollbackUserCreationAsync(user);
            EnsureSuccess(roleResult);
        }

        return new UserResponse(user.Id, user.Email!, user.DisplayName, ApplicationRoles.StoreStaff);
    }

    public async Task<PagedResponse<UserAccountResponse>> GetUsersAsync(
        int page,
        int pageSize,
        string? search,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var query = userManager.Users.AsNoTracking();
        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim();
            query = query.Where(user =>
                (user.Email != null && user.Email.Contains(term)) ||
                user.DisplayName.Contains(term));
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var users = await query
            .OrderBy(user => user.DisplayName)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var items = new List<UserAccountResponse>(users.Count);
        foreach (var user in users)
        {
            var roles = await userManager.GetRolesAsync(user);
            items.Add(new UserAccountResponse(
                user.Id,
                user.Email ?? string.Empty,
                user.DisplayName,
                roles.ToArray()));
        }

        return new PagedResponse<UserAccountResponse>(
            items,
            page,
            pageSize,
            totalCount,
            (int)Math.Ceiling(totalCount / (double)pageSize));
    }

    public async Task<UserAccountResponse?> UpdateUserAsync(
        Guid userId,
        UpdateUserRequest request,
        Guid currentUserId,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var user = await userManager.FindByIdAsync(userId.ToString());
        if (user is null)
        {
            return null;
        }

        var requestedRoles = NormalizeRoles(request.Roles);
        if (userId == currentUserId && !requestedRoles.Contains(ApplicationRoles.Admin))
        {
            throw new DataConflictException(ApiMessages.CannotRemoveOwnAdminRole);
        }

        user.DisplayName = request.DisplayName.Trim();
        var update = await userManager.UpdateAsync(user);
        EnsureSuccess(update);

        var currentRoles = await userManager.GetRolesAsync(user);
        var toRemove = currentRoles.Except(requestedRoles, StringComparer.OrdinalIgnoreCase).ToArray();
        var toAdd = requestedRoles.Except(currentRoles, StringComparer.OrdinalIgnoreCase).ToArray();
        if (toRemove.Length > 0)
        {
            EnsureSuccess(await userManager.RemoveFromRolesAsync(user, toRemove));
        }

        if (toAdd.Length > 0)
        {
            EnsureSuccess(await userManager.AddToRolesAsync(user, toAdd));
        }

        if (!string.IsNullOrWhiteSpace(request.NewPassword))
        {
            var resetToken = await userManager.GeneratePasswordResetTokenAsync(user);
            EnsureSuccess(await userManager.ResetPasswordAsync(user, resetToken, request.NewPassword));
        }

        var roles = await userManager.GetRolesAsync(user);
        return new UserAccountResponse(
            user.Id,
            user.Email ?? string.Empty,
            user.DisplayName,
            roles.ToArray());
    }

    public async Task<bool> DeleteUserAsync(
        Guid userId,
        Guid currentUserId,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        if (userId == currentUserId)
        {
            throw new DataConflictException(ApiMessages.CannotDeleteOwnAccount);
        }

        var user = await userManager.FindByIdAsync(userId.ToString());
        if (user is null)
        {
            return false;
        }

        try
        {
            var result = await userManager.DeleteAsync(user);
            if (!result.Succeeded)
            {
                throw new DataConflictException(ApiMessages.AccountDeleteFailed);
            }
        }
        catch (DbUpdateException exception)
        {
            // Orders reference their customer with a restrict FK; keep the history intact.
            throw new DataConflictException(ApiMessages.AccountHasOrders, exception);
        }

        return true;
    }

    /// <summary>Keeps only the seeded roles and rejects anything else.</summary>
    private static IReadOnlyList<string> NormalizeRoles(IReadOnlyList<string> roles)
    {
        var allowed = new[]
        {
            ApplicationRoles.Admin,
            ApplicationRoles.StoreStaff,
            ApplicationRoles.Customer
        };
        var normalized = roles
            .Where(role => !string.IsNullOrWhiteSpace(role))
            .Select(role => allowed.FirstOrDefault(candidate =>
                string.Equals(candidate, role.Trim(), StringComparison.OrdinalIgnoreCase)) ?? role.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();
        if (normalized.Length == 0 || normalized.Any(role => !allowed.Contains(role, StringComparer.Ordinal)))
        {
            throw new ArgumentException(ApiMessages.InvalidRoleAssignment, nameof(roles));
        }

        return normalized;
    }

    private async Task<AuthResponse> CreateAuthResponseAsync(ApplicationUser user)
    {
        var roles = await userManager.GetRolesAsync(user);
        return tokenIssuer.Issue(user, roles.ToArray());
    }

    private async Task RollbackUserCreationAsync(ApplicationUser user)
    {
        var result = await userManager.DeleteAsync(user);
        if (!result.Succeeded)
        {
            throw new InvalidOperationException(
                ApiMessages.AccountRollbackFailed(string.Join(" ", result.Errors.Select(error => error.Description))));
        }
    }

    private static void EnsureSuccess(IdentityResult result)
    {
        if (result.Succeeded)
        {
            return;
        }

        var isConflict = result.Errors.Any(error => error.Code.Contains("Duplicate", StringComparison.Ordinal));
        var detail = string.Join(" ", result.Errors.Select(error => error.Description));
        throw new AuthenticationOperationException(
            isConflict ? StatusCodes.Status409Conflict : StatusCodes.Status400BadRequest,
            isConflict ? ApiMessages.AccountAlreadyExistsTitle : ApiMessages.AccountCreationFailedTitle,
            detail);
    }
}
