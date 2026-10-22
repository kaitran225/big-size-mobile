using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace BigFit.Api.Realtime;

[Authorize]
public sealed class NotificationHub : Hub
{
    //TODO: Implement notification hub methods for real-time communication with clients.
}
