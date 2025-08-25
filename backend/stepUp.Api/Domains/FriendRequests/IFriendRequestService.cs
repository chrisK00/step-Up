namespace stepUp.Api.Domains.FriendRequests;

public interface IFriendRequestService
{
    Task<IEnumerable<GetFriendRequestsResponse>> GetFriendRequestsAsync(GetFriendRequests request, CancellationToken cancellation);
    Task<CommandResult> SendFriendRequestAsync(SendFriendRequest request, CancellationToken cancellation);
    Task<CommandResult> AcceptFriendRequestAsync(AcceptFriendRequest request, CancellationToken cancellation);
    Task<CommandResult> DeleteFriendRequestAsync(DeleteFriendRequest request, CancellationToken cancellation);
}
