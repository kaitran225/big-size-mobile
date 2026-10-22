using BigFit.Application.Abstractions;
using BigFit.Application.Authentication;
using Microsoft.AspNetCore.Identity;

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
