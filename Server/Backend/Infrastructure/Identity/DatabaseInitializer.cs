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
                        $"Could not initialize the {role} role: {string.Join(" ", result.Errors.Select(error => error.Description))}");
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
                "Both Auth:BootstrapAdmin:Email and Auth:BootstrapAdmin:Password must be configured together.");
        }

        var admin = await userManager.FindByEmailAsync(email);
        if (admin is not null && !await userManager.IsInRoleAsync(admin, ApplicationRoles.Admin))
        {
            throw new InvalidOperationException(
                "The configured bootstrap administrator email already belongs to a non-admin user. Choose a dedicated bootstrap email.");
        }

        if (admin is null)
        {
            admin = new ApplicationUser
            {
                Id = Guid.NewGuid(),
                UserName = email,
                Email = email,
                DisplayName = "BigFit Administrator"
            };
            var createResult = await userManager.CreateAsync(admin, password);
            if (!createResult.Succeeded)
            {
                throw new InvalidOperationException(
                    $"Could not create the configured bootstrap administrator: {string.Join(" ", createResult.Errors.Select(error => error.Description))}");
            }

            logger.LogInformation("Created configured bootstrap administrator {Email}.", email);
            var roleResult = await userManager.AddToRoleAsync(admin, ApplicationRoles.Admin);
            if (!roleResult.Succeeded)
            {
                var deleteResult = await userManager.DeleteAsync(admin);
                if (!deleteResult.Succeeded)
                {
                    throw new InvalidOperationException(
                        $"Could not assign the Admin role and could not remove the incomplete bootstrap user: {string.Join(" ", deleteResult.Errors.Select(error => error.Description))}");
                }

                throw new InvalidOperationException(
                    $"Could not assign the Admin role to the configured bootstrap account: {string.Join(" ", roleResult.Errors.Select(error => error.Description))}");
            }
        }
    }
}
