using BigFit.Application;
using BigFit.Application.Abstractions;
using BigFit.Application.Catalog;
using BigFit.Application.Notifications;
using BigFit.Application.Shopping;
using BigFit.Domain.Entities;
using BigFit.Infrastructure.Identity;
using BigFit.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BigFit.Infrastructure.Shopping;

internal sealed class OrderFulfillmentService(
    BigFitDbContext dbContext,
    INotificationService notifications,
    INotificationEventPublisher eventPublisher) : IOrderFulfillmentService
{
    private const string CodProvider = "Cod";

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
        Guid staffUserId,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        _ = staffUserId;

        var order = await dbContext.Orders
            .Include(item => item.Items)
            .SingleOrDefaultAsync(item => item.Id == orderId, cancellationToken);
        if (order is null)
        {
            return null;
        }

        var nextStatus = action switch
        {
            "accept" => await ResolveAcceptStatusAsync(order, cancellationToken),
            "ship" when order.Status == "Processing" => "Shipped",
            "complete" when order.Status == "Shipped" => "Delivered",
            _ => null
        };

        if (nextStatus is null)
        {
            throw new ArgumentException(ApiMessages.InvalidFulfillmentTransition, nameof(action));
        }

        order.Status = nextStatus;
        order.UpdatedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);

        await NotifyCustomerAsync(order, action, cancellationToken);

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
        return order.Status switch
        {
            "Confirmed" => "Processing",
            "Pending" => await CanAcceptCodAsync(order.Id, cancellationToken)
                ? "Processing"
                : null,
            _ => null
        };
    }

    private async Task<bool> CanAcceptCodAsync(Guid orderId, CancellationToken cancellationToken) =>
        await dbContext.Payments.AsNoTracking().AnyAsync(
            payment =>
                payment.OrderId == orderId &&
                payment.Provider == CodProvider &&
                payment.Method == "cod",
            cancellationToken);

    private async Task NotifyCustomerAsync(
        CustomerOrder order,
        string action,
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
                    DataJson =
                        $"{{\"orderId\":\"{order.Id}\",\"status\":\"{order.Status}\"}}"
                },
                cancellationToken);
        }
        catch
        {
            // Notification failure should not roll back fulfilment.
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
