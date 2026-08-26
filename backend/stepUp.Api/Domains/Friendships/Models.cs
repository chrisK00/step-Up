namespace stepUp.Api.Domains.Friendships;

public record DeleteFriendshipRequest(string UserId, string FriendId);
public record GetFriendshipsResponse(string UserId, string FirstName, bool HasThumbsUpToday);
public record SendFriendReactionRequest(string UserId, string FriendId);
