using Microsoft.EntityFrameworkCore;
using stepUp.Api.Data;
using stepUp.Api.Data.Entities;
using stepUp.Api.Utils;

namespace stepUp.Api.Domains.Friendships;

internal class FriendshipService(AppDbContext dbContext, IUnitOfWork unitOfWork) : IFriendshipService
{
    public async Task<CommandResult> DeleteFriendshipAsync(DeleteFriendshipRequest request, CancellationToken cancellation)
    {
        var (userIdSmaller, userIdLarger) = UserIdUtil.OrderUserIds(request.UserId, request.FriendId);
        var existingFriendship = await dbContext.Friendships.SingleOrDefaultAsync(f => f.UserId == userIdSmaller && f.FriendId == userIdLarger, cancellation);
        if (existingFriendship == null)
        {
            return CommandResult.Fail("Friendship does not exist");
        }

        dbContext.Remove(existingFriendship);
        await unitOfWork.SaveChangesAsync(cancellation);
        return CommandResult.Ok();
    }

    public async Task<IEnumerable<GetFriendshipsResponse>> GetFriendshipsAsync(string userId, CancellationToken cancellation)
    {
        var friendIds = await dbContext.Friendships.AsNoTracking()
            .Where(f => f.UserId == userId || f.FriendId == userId)
            .Select(f => f.UserId == userId ? f.FriendId : f.UserId)
            .ToListAsync(cancellation);

        return await dbContext.Users.AsNoTracking()
            .Where(u => friendIds.Contains(u.UserId))
            .OrderBy(u => u.FirstName)
            .Select(u => new GetFriendshipsResponse(u.UserId, u.FirstName))
            .ToListAsync(cancellation);
    }

    public async Task<IEnumerable<ReceivedReactionResponse>> GetReceivedReactionsAsync(string userId, CancellationToken cancellation)
    {
        var today = DateOnly.FromDateTime(DateTime.Today);
        var normalizedUserId = userId.Trim().ToLower();

        var reactions = await dbContext.FriendReactions.AsNoTracking()
            .Where(r => r.FriendId.ToLower() == normalizedUserId && r.Date == today)
            .ToListAsync(cancellation);

        if (reactions.Count == 0)
        {
            return [];
        }

        var senderIds = reactions.Select(r => r.UserId.ToLower()).ToHashSet();
        var senders = await dbContext.Users.AsNoTracking()
            .Where(u => senderIds.Contains(u.UserId.ToLower()))
            .ToDictionaryAsync(u => u.UserId.ToLower(), u => u.FirstName, cancellation);

        return reactions.Select(r =>
        {
            senders.TryGetValue(r.UserId.ToLower(), out var firstName);
            return new ReceivedReactionResponse(firstName ?? "Friend");
        }).ToList();
    }

    public async Task<CommandResult> SendThumbsUpAsync(SendFriendReactionRequest request, CancellationToken cancellation)
    {
        var (userIdSmaller, userIdLarger) = UserIdUtil.OrderUserIds(request.UserId, request.FriendId);
        var friendshipExists = await dbContext.Friendships.AsNoTracking()
            .AnyAsync(f =>
                (f.UserId.ToLower() == userIdSmaller.ToLower() && f.FriendId.ToLower() == userIdLarger.ToLower()) ||
                (f.UserId.ToLower() == request.UserId.ToLower() && f.FriendId.ToLower() == request.FriendId.ToLower()) ||
                (f.UserId.ToLower() == request.FriendId.ToLower() && f.FriendId.ToLower() == request.UserId.ToLower()), cancellation);
        if (!friendshipExists)
        {
            return CommandResult.Fail("Friendship does not exist");
        }

        var today = DateOnly.FromDateTime(DateTime.Today);
        var existing = await dbContext.FriendReactions.SingleOrDefaultAsync(x =>
            x.UserId.ToLower() == request.UserId.ToLower() &&
            x.FriendId.ToLower() == request.FriendId.ToLower() &&
            x.Date == today, cancellation);

        if (existing == null)
        {
            await dbContext.FriendReactions.AddAsync(new FriendReaction
            {
                UserId = request.UserId,
                FriendId = request.FriendId,
                Date = today,
                ReactionType = "ThumbsUp",
            }, cancellation);
        }

        await unitOfWork.SaveChangesAsync(cancellation);
        return CommandResult.Ok();
    }
}
