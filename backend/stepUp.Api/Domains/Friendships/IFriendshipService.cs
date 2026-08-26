namespace stepUp.Api.Domains.Friendships;

public interface IFriendshipService
{
    Task<CommandResult> DeleteFriendshipAsync(DeleteFriendshipRequest request, CancellationToken cancellation);
    Task<IEnumerable<GetFriendshipsResponse>> GetFriendshipsAsync(string userId, CancellationToken cancellation);
    Task<IEnumerable<ReceivedReactionResponse>> GetReceivedReactionsAsync(string userId, CancellationToken cancellation);
    Task<CommandResult> SendThumbsUpAsync(SendFriendReactionRequest request, CancellationToken cancellation);
}
