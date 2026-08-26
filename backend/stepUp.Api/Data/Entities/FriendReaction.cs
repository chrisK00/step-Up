namespace stepUp.Api.Data.Entities;

public class FriendReaction
{
    public string UserId { get; set; }
    public string FriendId { get; set; }
    public DateOnly Date { get; set; } = DateOnly.FromDateTime(DateTime.Today);
    public string ReactionType { get; set; } = "ThumbsUp";
}
