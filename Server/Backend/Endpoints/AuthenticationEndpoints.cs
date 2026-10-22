using BigFit.Application.Abstractions;
using BigFit.Application.Authentication;
using Microsoft.AspNetCore.Http.HttpResults;

namespace BigFit.Api.Endpoints;

public static class AuthenticationEndpoints
{
    public static IEndpointRouteBuilder MapAuthenticationEndpoints(this IEndpointRouteBuilder endpoints)
    {
        var group = endpoints.MapGroup("/api/auth").WithTags(ApiMessages.TagAuthentication);

        group.MapPost("/register", async Task<Ok<AuthResponse>> (
            RegisterCustomerRequest request,
            IAuthenticationService authentication,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await authentication.RegisterCustomerAsync(request, cancellationToken)))
            .WithName("RegisterCustomer")
            .WithSummary(ApiMessages.SummaryRegisterCustomer)
            .RequireRateLimiting("authentication");

        group.MapPost("/login", async Task<Results<Ok<AuthResponse>, UnauthorizedHttpResult>> (
            LoginRequest request,
            IAuthenticationService authentication,
            CancellationToken cancellationToken) =>
        {
            var response = await authentication.LoginAsync(request, cancellationToken);
            return response is null ? TypedResults.Unauthorized() : TypedResults.Ok(response);
        })
        .WithName("Login")
        .WithSummary(ApiMessages.SummaryLogin)
        .RequireRateLimiting("authentication");

        endpoints.MapPost("/api/admin/staff", async Task<Created<UserResponse>> (
            CreateStoreStaffRequest request,
            IAuthenticationService authentication,
            CancellationToken cancellationToken) =>
        {
            var user = await authentication.CreateStoreStaffAsync(request, cancellationToken);
            return TypedResults.Created($"/api/admin/staff/{user.Id}", user);
        })
        .WithTags(ApiMessages.TagAdministration)
        .WithName("CreateStoreStaff")
        .WithSummary(ApiMessages.SummaryCreateStoreStaff)
        .RequireAuthorization(ApplicationRoles.Admin)
        .RequireRateLimiting("authentication");

        return endpoints;
    }
}
