using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using BigFit.Application.Authentication;
using Microsoft.IdentityModel.Tokens;

namespace BigFit.Infrastructure.Identity;

internal sealed class JwtTokenIssuer(IConfiguration configuration)
{
    public AuthResponse Issue(ApplicationUser user, IReadOnlyList<string> roles)
    {
        var issuer = configuration["Auth:Jwt:Issuer"]!;
        var audience = configuration["Auth:Jwt:Audience"]!;
        var signingKey = configuration["Auth:Jwt:SigningKey"]!;
        var lifetimeMinutes = int.TryParse(configuration["Auth:Jwt:AccessTokenMinutes"], out var minutes)
            ? Math.Clamp(minutes, 5, 120)
            : 30;
        var expiresAt = DateTimeOffset.UtcNow.AddMinutes(lifetimeMinutes);
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(signingKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new(ClaimTypes.Name, user.DisplayName),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };
        claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));

        var token = new JwtSecurityToken(
            issuer,
            audience,
            claims,
            notBefore: DateTime.UtcNow,
            expires: expiresAt.UtcDateTime,
            signingCredentials: credentials);

        return new AuthResponse(
            new JwtSecurityTokenHandler().WriteToken(token),
            expiresAt,
            user.Email ?? string.Empty,
            user.DisplayName,
            roles);
    }
}
