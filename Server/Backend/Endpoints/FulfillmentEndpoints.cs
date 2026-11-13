using System.Security.Claims;
using BigFit.Application.Abstractions;
using BigFit.Application.Authentication;
using BigFit.Application.Catalog;
using BigFit.Application.Shopping;
using Microsoft.AspNetCore.Http.HttpResults;

namespace BigFit.Api.Endpoints;

public static class FulfillmentEndpoints
{
    public static IEndpointRouteBuilder MapFulfillmentEndpoints(this IEndpointRouteBuilder endpoints)
    {
        var group = endpoints.MapGroup("/api/fulfillment")
            .WithTags(ApiMessages.TagFulfillment)
            .RequireAuthorization(ApplicationRoles.OrderFulfillment);

        group.MapGet("/orders", async Task<Results<Ok<PagedResponse<StaffOrderResponse>>, BadRequest>> (
            IOrderFulfillmentService fulfillment,
            int? page,
            int? pageSize,
            bool? includeDelivered,
            CancellationToken cancellationToken) =>
        {
            var requestedPage = page ?? 1;
            var requestedPageSize = pageSize ?? 20;
            if (requestedPage < 1 || requestedPageSize is < 1 or > 100)
            {
                return TypedResults.BadRequest();
            }

            return TypedResults.Ok(await fulfillment.GetQueueAsync(
                requestedPage,
                requestedPageSize,
                includeDelivered ?? false,
                cancellationToken));
        })
        .WithName("GetFulfillmentOrders")
        .WithSummary(ApiMessages.SummaryGetFulfillmentOrders);

        group.MapPatch("/orders/{orderId:guid}", async Task<Results<Ok<StaffOrderResponse>, NotFound>> (
            Guid orderId,
            FulfillmentActionRequest request,
            IOrderFulfillmentService fulfillment,
            ClaimsPrincipal user,
            CancellationToken cancellationToken) =>
        {
            var result = await fulfillment.ApplyActionAsync(
                orderId,
                request.Action,
                request.Reason,
                GetUserId(user),
                cancellationToken);
            return result is null ? TypedResults.NotFound() : TypedResults.Ok(result);
        })
        .WithName("ApplyFulfillmentAction")
        .WithSummary(ApiMessages.SummaryApplyFulfillmentAction);

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
