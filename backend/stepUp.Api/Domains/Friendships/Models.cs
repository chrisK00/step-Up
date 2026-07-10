namespace stepUp.Api.Domains.Friendships;

public record DeleteFriendshipRequest(string UserId, string FriendId);
public record GetFriendshipsResponse(string UserId, string FirstName);