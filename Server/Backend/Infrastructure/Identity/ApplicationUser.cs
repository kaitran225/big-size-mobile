using Microsoft.AspNetCore.Identity;

namespace BigFit.Infrastructure.Identity;

public sealed class ApplicationUser : IdentityUser<Guid>
{
    public required string DisplayName { get; set; }
}
