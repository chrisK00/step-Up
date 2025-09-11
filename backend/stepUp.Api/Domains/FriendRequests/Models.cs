using stepUp.Api.Utils;
using System.ComponentModel.DataAnnotations;

namespace stepUp.Api.Domains.FriendRequests;

public record SendFriendRequest(string UserId, [Required(AllowEmptyStrings = false)] string ToUserId);
public record AcceptFriendRequest(string UserId, [Required(AllowEmptyStrings = false)] string FromUserId);
public record DeleteFriendRequest(string UserId, [Required(AllowEmptyStrings = false)] string OtherUserId);

public record GetFriendRequests(string UserId, FriendRequestType FriendRequestType);
public record GetFriendRequestsResponse(string FromUserId, string FromUsername, string ToUsername, string ToUserId, DateTime SentDateTime);

public enum FriendRequestType
{
    Incoming,
    Outgoing
}
