namespace stepUp.Api.Utils;

// TODO move to business layer
public static class UserIdUtil
{
    public static (string smaller, string larger) OrderUserIds(string userId1, string userId2)
        => Guid.Parse(userId1).CompareTo(Guid.Parse(userId2)) < 0 ? (userId1, userId2) : (userId2, userId1);
}
