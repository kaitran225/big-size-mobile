using System.Security.Claims;
using BigFit.Application.Addresses;
using BigFit.Application.Abstractions;
using Microsoft.AspNetCore.Http.HttpResults;

namespace BigFit.Api.Endpoints;

public static class AddressEndpoints
{
    public static IEndpointRouteBuilder MapAddressEndpoints(this IEndpointRouteBuilder endpoints)
    {
        var group = endpoints.MapGroup("/api/addresses")
            .WithTags(ApiMessages.TagDeliveryAddresses)
            .RequireAuthorization();

        group.MapGet("/", async Task<Ok<IReadOnlyList<CustomerAddressResponse>>> (
            IAddressService addresses,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                TypedResults.Ok(await addresses.GetMineAsync(GetUserId(user), cancellationToken)))
            .WithName("GetMyAddresses")
            .WithSummary(ApiMessages.SummaryGetMyAddresses);

        group.MapPost("/", async Task<Created<CustomerAddressResponse>> (
            CustomerAddressRequest request,
            IAddressService addresses,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
        {
            var created = await addresses.CreateAsync(GetUserId(user), request, cancellationToken);
            return TypedResults.Created($"/api/addresses/{created.Id}", created);
        })
        .WithName("CreateMyAddress")
        .WithSummary(ApiMessages.SummaryCreateMyAddress);

        group.MapPut("/{addressId:guid}", async Task<Results<Ok<CustomerAddressResponse>, NotFound>> (
            Guid addressId,
            CustomerAddressRequest request,
            IAddressService addresses,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
        {
            var updated = await addresses.UpdateAsync(
                GetUserId(user), addressId, request, cancellationToken);
            return updated is null ? TypedResults.NotFound() : TypedResults.Ok(updated);
        })
        .WithName("UpdateMyAddress")
        .WithSummary(ApiMessages.SummaryUpdateMyAddress);

        group.MapDelete("/{addressId:guid}", async Task<Results<NoContent, NotFound>> (
            Guid addressId,
            IAddressService addresses,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
                await addresses.DeleteAsync(GetUserId(user), addressId, cancellationToken)
                    ? TypedResults.NoContent()
                    : TypedResults.NotFound())
            .WithName("DeleteMyAddress")
            .WithSummary(ApiMessages.SummaryDeleteMyAddress);

        return endpoints;
    }

    private static Guid GetUserId(ClaimsPrincipal user)
    {
        var subject = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? user.FindFirstValue("sub");
        return Guid.TryParse(subject, out var userId)
            ? userId
            : throw new InvalidOperationException(ApiMessages.AuthenticatedTokenWithoutUserId);
    }
}
