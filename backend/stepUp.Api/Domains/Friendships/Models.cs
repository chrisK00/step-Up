namespace stepUp.Api.Domains.Friendships;

public record DeleteFriendshipRequest(string UserId = "", string FriendId = "");
public record GetFriendshipsResponse(string UserId, string FirstName);
public record ReceivedReactionResponse(string FromUsername);
public record SendFriendReactionRequest(string UserId = "", string FriendId = "");
