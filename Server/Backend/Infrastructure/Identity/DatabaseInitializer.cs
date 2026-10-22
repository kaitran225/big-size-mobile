using BigFit.Application.Abstractions;
using BigFit.Application.Authentication;
using Microsoft.AspNetCore.Identity;

namespace BigFit.Infrastructure.Identity;

internal sealed class DatabaseInitializer(
    RoleManager<IdentityRole<Guid>> roleManager,
    UserManager<ApplicationUser> userManager,
    IConfiguration configuration,
    ILogger<DatabaseInitializer> logger)
{
    public async Task InitializeAsync(CancellationToken cancellationToken)
    {
        foreach (var role in new[]
        {
            ApplicationRoles.Admin,
            ApplicationRoles.StoreStaff,
            ApplicationRoles.Customer
        })
        {
            cancellationToken.ThrowIfCancellationRequested();
            if (!await roleManager.RoleExistsAsync(role))
            {
                var result = await roleManager.CreateAsync(new IdentityRole<Guid>(role));
                if (!result.Succeeded)
                {
                    throw new InvalidOperationException(
                        ApiMessages.RoleInitializationFailed(role, string.Join(" ", result.Errors.Select(error => error.Description))));
                }
            }
        }

        var email = configuration["Auth:BootstrapAdmin:Email"];
        var password = configuration["Auth:BootstrapAdmin:Password"];
        if (string.IsNullOrWhiteSpace(email) && string.IsNullOrWhiteSpace(password))
        {
            return;
        }

        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
        {
            throw new InvalidOperationException(
                ApiMessages.BootstrapCredentialsMustBePaired);
        }

        var admin = await userManager.FindByEmailAsync(email);
        if (admin is not null && !await userManager.IsInRoleAsync(admin, ApplicationRoles.Admin))
        {
            throw new InvalidOperationException(
                ApiMessages.BootstrapEmailBelongsToNonAdmin);
        }

        if (admin is null)
        {
            admin = new ApplicationUser
            {
                Id = Guid.NewGuid(),
                UserName = email,
                Email = email,
                DisplayName = ApiMessages.BootstrapAdminDisplayName
            };
            var createResult = await userManager.CreateAsync(admin, password);
            if (!createResult.Succeeded)
            {
                throw new InvalidOperationException(
                    ApiMessages.BootstrapAdminCreationFailed(string.Join(" ", createResult.Errors.Select(error => error.Description))));
            }

            logger.LogInformation(ApiMessages.BootstrapAdminCreatedLog, email);
            var roleResult = await userManager.AddToRoleAsync(admin, ApplicationRoles.Admin);
            if (!roleResult.Succeeded)
            {
                var deleteResult = await userManager.DeleteAsync(admin);
                if (!deleteResult.Succeeded)
                {
                    throw new InvalidOperationException(
                        ApiMessages.BootstrapRoleAssignmentAndCleanupFailed(string.Join(" ", deleteResult.Errors.Select(error => error.Description))));
                }

                throw new InvalidOperationException(
                    ApiMessages.BootstrapRoleAssignmentFailed(string.Join(" ", roleResult.Errors.Select(error => error.Description))));
            }
        }
    }
}
