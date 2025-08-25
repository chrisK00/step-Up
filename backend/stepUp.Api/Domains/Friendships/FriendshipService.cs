using Microsoft.EntityFrameworkCore;
using stepUp.Api.Data;
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
        return await (
         from f in dbContext.Friendships.AsNoTracking()
         where f.UserId == userId || f.FriendId == userId
         let friendId = f.UserId == userId ? f.FriendId : f.UserId
         join u in dbContext.Users.AsNoTracking()
             on friendId equals u.UserId
         select new GetFriendshipsResponse(u.UserId.ToString(), u.FirstName))
         .ToListAsync(cancellation);
    }
}
