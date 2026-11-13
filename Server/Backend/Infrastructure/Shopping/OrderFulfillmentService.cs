using BigFit.Application;
using BigFit.Application.Abstractions;
using BigFit.Application.Catalog;
using BigFit.Application.Notifications;
using BigFit.Application.Shopping;
using BigFit.Domain.Entities;
using BigFit.Infrastructure.Identity;
using BigFit.Infrastructure.Persistence;
using System.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace BigFit.Infrastructure.Shopping;

internal sealed class OrderFulfillmentService(
    BigFitDbContext dbContext,
    INotificationService notifications,
    INotificationEventPublisher eventPublisher,
    ILogger<OrderFulfillmentService> logger) : IOrderFulfillmentService
{
    private const string CodProvider = "Cod";
    private const string SePayProvider = "SePay";
    private const string CodMethod = "cod";
    private const string BankMethod = "bankTransfer";

    public async Task<PagedResponse<StaffOrderResponse>> GetQueueAsync(
        int page,
        int pageSize,
        bool includeDelivered,
        CancellationToken cancellationToken)
    {
        var query = dbContext.Orders.AsNoTracking()
            .Include(order => order.Items)
            .OrderByDescending(order => order.CreatedAt)
            .AsQueryable();

        if (!includeDelivered)
        {
            query = query.Where(order => order.Status != "Delivered");
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var orders = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
        var userIds = orders.Select(order => order.UserId).Distinct().ToArray();
        var users = await dbContext.Users.AsNoTracking()
            .Where(user => userIds.Contains(user.Id))
            .ToDictionaryAsync(user => user.Id, cancellationToken);
        var orderIds = orders.Select(order => order.Id).ToArray();
        var paymentRows = await dbContext.Payments.AsNoTracking()
            .Where(payment => orderIds.Contains(payment.OrderId))
            .ToListAsync(cancellationToken);
        var payments = paymentRows
            .GroupBy(payment => payment.OrderId)
            .ToDictionary(
                group => group.Key,
                group => group.OrderByDescending(item => item.CreatedAt).First());

        var items = orders
            .Select(order => MapStaffOrder(order, users, payments))
            .ToArray();

        return new PagedResponse<StaffOrderResponse>(
            items,
            page,
            pageSize,
            totalCount,
            (int)Math.Ceiling(totalCount / (double)pageSize));
    }

    public async Task<StaffOrderResponse?> ApplyActionAsync(
        Guid orderId,
        string action,
        string? reason,
        Guid staffUserId,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        _ = staffUserId;

        await using var transaction = await dbContext.Database.BeginTransactionAsync(
            IsolationLevel.Serializable,
            cancellationToken);
        var order = await dbContext.Orders
            .Include(item => item.Items)
            .SingleOrDefaultAsync(item => item.Id == orderId, cancellationToken);
        if (order is null)
        {
            return null;
        }

        if (action == "reject")
        {
            await RejectOrderAsync(order, reason, cancellationToken);
        }
        else
        {
            var nextStatus = action switch
            {
                "accept" => await ResolveAcceptStatusAsync(order, cancellationToken),
                "ship" when order.Status == "Processing" => "Shipped",
                "complete" when order.Status == "Shipped" => "Delivered",
                _ => null
            };

            if (nextStatus is null)
            {
                throw new DataConflictException(action == "accept"
                    ? ApiMessages.OrderCannotBeAccepted
                    : ApiMessages.InvalidFulfillmentTransition);
            }

            order.Status = nextStatus;
        }

        order.UpdatedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        await NotifyCustomerAsync(order, action, reason, cancellationToken);

        var change = new OrderStatusChangedEvent(order.Id, order.Status, order.UpdatedAt);
        await eventPublisher.PublishOrderStatusChangedAsync(order.UserId, change, cancellationToken);

        var user = await dbContext.Users.AsNoTracking()
            .SingleAsync(item => item.Id == order.UserId, cancellationToken);
        var payment = await dbContext.Payments.AsNoTracking()
            .Where(item => item.OrderId == order.Id)
            .OrderByDescending(item => item.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);
        var payments = payment is null
            ? new Dictionary<Guid, Payment>()
            : new Dictionary<Guid, Payment> { [order.Id] = payment };

        return MapStaffOrder(order, new Dictionary<Guid, ApplicationUser> { [user.Id] = user }, payments);
    }

    private async Task<string?> ResolveAcceptStatusAsync(
        CustomerOrder order,
        CancellationToken cancellationToken)
    {
        if (order.Status == "Confirmed")
        {
            return "Processing";
        }

        if (order.Status != "Pending")
        {
            return null;
        }

        var payment = await dbContext.Payments
            .Where(item => item.OrderId == order.Id)
            .OrderByDescending(item => item.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);
        if (payment is null)
        {
            return null;
        }

        if (payment.Provider == CodProvider &&
            payment.Method == CodMethod &&
            payment.Status == "Pending")
        {
            return "Processing";
        }

        if (payment.Provider != SePayProvider ||
            payment.Method != BankMethod ||
            payment.Status != "Succeeded")
        {
            return null;
        }

        return "Processing";
    }

    private async Task RejectOrderAsync(
        CustomerOrder order,
        string? reason,
        CancellationToken cancellationToken)
    {
        var normalizedReason = reason?.Trim();
        if (string.IsNullOrWhiteSpace(normalizedReason))
        {
            throw new ArgumentException(ApiMessages.RejectionReasonRequired, nameof(reason));
        }

        if (normalizedReason.Length > 500)
        {
            throw new ArgumentException(
                ApiMessages.InvalidFulfillmentTransition,
                nameof(reason));
        }

        var payments = await dbContext.Payments
            .Where(item => item.OrderId == order.Id)
            .ToListAsync(cancellationToken);
        if (order.Status != "Pending" ||
            payments.Any(item => item.Status == "Succeeded"))
        {
            throw new DataConflictException(ApiMessages.OrderCannotBeRejected);
        }

        var now = DateTimeOffset.UtcNow;
        foreach (var payment in payments.Where(item => item.Status == "Pending"))
        {
            payment.Status = "Cancelled";
            payment.CompletedAt = now;
        }

        var variantIds = order.Items
            .Where(item => item.ProductVariantId.HasValue)
            .Select(item => item.ProductVariantId!.Value)
            .ToArray();
        if (variantIds.Length > 0)
        {
            var variants = await dbContext.ProductVariants
                .Where(item => variantIds.Contains(item.Id))
                .ToDictionaryAsync(item => item.Id, cancellationToken);
            foreach (var item in order.Items)
            {
                if (item.ProductVariantId is Guid variantId &&
                    variants.TryGetValue(variantId, out var variant))
                {
                    variant.StockQuantity += item.Quantity;
                }
            }
        }

        order.Status = "Cancelled";
        order.RejectionReason = normalizedReason;
    }

    private async Task NotifyCustomerAsync(
        CustomerOrder order,
        string action,
        string? reason,
        CancellationToken cancellationToken)
    {
        var (title, message) = action switch
        {
            "accept" => (
                $"Order {order.OrderNumber} accepted",
                "Your order is now being prepared."),
            "ship" => (
                $"Order {order.OrderNumber} shipped",
                "Your package is on the way."),
            "complete" => (
                $"Order {order.OrderNumber} delivered",
                "Your order has been delivered."),
            "reject" => (
                $"Order {order.OrderNumber} was rejected",
                $"Reason: {reason!.Trim()}"),
            _ => (string.Empty, string.Empty)
        };

        if (string.IsNullOrEmpty(title))
        {
            return;
        }

        try
        {
            await notifications.CreateForUserAsync(
                order.UserId,
                new CreateNotificationRequest
                {
                    Type = "order",
                    Title = title,
                    Message = message,
                    DataJson = System.Text.Json.JsonSerializer.Serialize(new
                    {
                        orderId = order.Id,
                        status = order.Status,
                        reason = action == "reject" ? reason?.Trim() : null
                    })
                },
                cancellationToken);
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            logger.LogWarning(
                exception,
                "Could not send the customer notification for order {OrderId}.",
                order.Id);
        }
    }

    private static StaffOrderResponse MapStaffOrder(
        CustomerOrder order,
        IReadOnlyDictionary<Guid, ApplicationUser> users,
        IReadOnlyDictionary<Guid, Payment> payments)
    {
        users.TryGetValue(order.UserId, out var user);
        payments.TryGetValue(order.Id, out var payment);
        return new StaffOrderResponse(
            order.Id,
            order.OrderNumber,
            order.Status,
            order.Subtotal,
            order.ShippingAmount,
            order.TotalAmount,
            order.CurrencyCode,
            order.RejectionReason,
            order.CreatedAt,
            order.UpdatedAt,
            order.UserId,
            user?.DisplayName ?? "Customer",
            user?.Email ?? string.Empty,
            payment?.Method,
            payment?.Status,
            order.Items.Select(item => new OrderItemResponse(
                item.Id,
                item.ProductName,
                item.Sku,
                item.Size,
                item.Color,
                item.Quantity,
                item.UnitPrice,
                item.LineTotal)).ToArray());
    }
}
