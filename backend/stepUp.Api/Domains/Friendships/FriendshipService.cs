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
        var today = DateOnly.FromDateTime(DateTime.Today);
        return await (
         from f in dbContext.Friendships.AsNoTracking()
         where f.UserId == userId || f.FriendId == userId
         let friendId = f.UserId == userId ? f.FriendId : f.UserId
         join u in dbContext.Users.AsNoTracking()
             on friendId equals u.UserId
         join r in dbContext.FriendReactions.AsNoTracking()
             on new { UserId = userId, FriendId = friendId, Date = today }
             equals new { r.UserId, r.FriendId, r.Date } into reactions
         from r in reactions.DefaultIfEmpty()
         orderby u.FirstName
         select new GetFriendshipsResponse(u.UserId.ToString(), u.FirstName, r != null))
         .ToListAsync(cancellation);
    }

    public async Task<IEnumerable<ReceivedReactionResponse>> GetReceivedReactionsAsync(string userId, CancellationToken cancellation)
    {
        var today = DateOnly.FromDateTime(DateTime.Today);
        return await (
            from r in dbContext.FriendReactions.AsNoTracking()
            where r.FriendId == userId && r.Date == today
            join u in dbContext.Users.AsNoTracking()
                on r.UserId equals u.UserId
            select new ReceivedReactionResponse(u.FirstName))
            .ToListAsync(cancellation);
    }

    public async Task<CommandResult> SendThumbsUpAsync(SendFriendReactionRequest request, CancellationToken cancellation)
    {
        var (userIdSmaller, userIdLarger) = UserIdUtil.OrderUserIds(request.UserId, request.FriendId);
        var friendshipExists = await dbContext.Friendships.AsNoTracking()
            .AnyAsync(f => f.UserId == userIdSmaller && f.FriendId == userIdLarger, cancellation);
        if (!friendshipExists)
        {
            return CommandResult.Fail("Friendship does not exist");
        }

        var today = DateOnly.FromDateTime(DateTime.Today);
        var existing = await dbContext.FriendReactions.SingleOrDefaultAsync(x =>
            x.UserId == request.UserId && x.FriendId == request.FriendId && x.Date == today, cancellation);

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
