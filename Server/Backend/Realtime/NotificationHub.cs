using BigFit.Application.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace BigFit.Api.Realtime;

[Authorize]
public sealed class NotificationHub : Hub
{
    public async Task SubscribeStaff()
    {
        if (Context.User?.IsInRole(ApplicationRoles.Admin) != true &&
            Context.User?.IsInRole(ApplicationRoles.StoreStaff) != true)
        {
            throw new HubException("Staff role required.");
        }

        await Groups.AddToGroupAsync(Context.ConnectionId, SignalRNotificationEventPublisher.StaffGroupName);
    }
}
