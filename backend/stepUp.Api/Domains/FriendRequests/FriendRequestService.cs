
using Microsoft.EntityFrameworkCore;
using stepUp.Api.Data;
using stepUp.Api.Data.Entities;
using stepUp.Api.Utils;

namespace stepUp.Api.Domains.FriendRequests;

internal class FriendRequestService(AppDbContext dbContext, IUnitOfWork unitOfWork) : IFriendRequestService
{    
    public async Task<CommandResult> AcceptFriendRequestAsync(AcceptFriendRequest request, CancellationToken cancellation)
    {
        var friendRequest = await dbContext.FriendRequests.SingleOrDefaultAsync(fr => fr.FromUserId == request.FromUserId && fr.ToUserId == request.UserId, cancellation);
        if (friendRequest == null)
        {
            return CommandResult.Fail("Friend request does not exist");
        }

        await CreateFriendshipAsync(request.UserId, request.FromUserId, cancellation);

        dbContext.FriendRequests.Remove(friendRequest);
        await unitOfWork.SaveChangesAsync(cancellation);

        return CommandResult.Ok();
    }

    public async Task<CommandResult> DeleteFriendRequestAsync(DeleteFriendRequest request, CancellationToken cancellation)
    {
        var existingFriendRequest = await dbContext.FriendRequests.SingleOrDefaultAsync(fr => (fr.FromUserId == request.UserId && fr.ToUserId == fr.ToUserId)
                                                                                            || (fr.ToUserId == request.UserId && fr.FromUserId == request.OtherUserId),
                                                                                             cancellation);
        if (existingFriendRequest == null)
        {
            return CommandResult.Fail("Friend request does not exist");
        }

        dbContext.FriendRequests.Remove(existingFriendRequest);
        await unitOfWork.SaveChangesAsync(cancellation);

        return CommandResult.Ok();
    }

    public async Task<IEnumerable<GetFriendRequestsResponse>> GetFriendRequestsAsync(GetFriendRequests request, CancellationToken cancellation)
    {
        var query = dbContext.FriendRequests.AsNoTracking().AsQueryable();
        query = request.FriendRequestType switch
        {
            FriendRequestType.Incoming => query.Where(fr => fr.ToUserId == request.UserId),
            FriendRequestType.Outgoing => query.Where(fr => fr.FromUserId == request.UserId),
            _ => throw new NotImplementedException(),
        };

        return await query
            .Select(fr => new GetFriendRequestsResponse(fr.FromUserId, fr.ToUserId, fr.SentDate))
            .ToListAsync(cancellation);
    }

    public async Task<CommandResult> SendFriendRequestAsync(SendFriendRequest request, CancellationToken cancellation)
    {
        if (request.UserId == request.ToUserId)
        {
            return CommandResult.Fail("Cannot befriend yourself");
        }

        var existingFriendRequest = await dbContext.FriendRequests.SingleOrDefaultAsync(fr => (fr.FromUserId == request.UserId && fr.ToUserId == fr.ToUserId)
                                                                                            || (fr.ToUserId == request.UserId && fr.FromUserId == request.ToUserId),
                                                                                             cancellation);

        if ((await FriendshipExists(request.UserId, request.ToUserId, cancellation)) || existingFriendRequest != null)
        {
            return CommandResult.Fail("Friend or friend request exists");
        }

        var toUserExists = await dbContext.Users.AnyAsync(u => u.UserId == request.ToUserId, cancellation);
        if (!toUserExists)
        {
            return CommandResult.Fail("User does not exist");
        }

        await dbContext.FriendRequests.AddAsync(new FriendRequest { FromUserId = request.UserId, ToUserId = request.ToUserId }, cancellation);
        await unitOfWork.SaveChangesAsync(cancellation);

        return CommandResult.Ok();
    }

    private async Task CreateFriendshipAsync(string userId, string friendId, CancellationToken cancellation)
    {
        var (userIdSmaller, userIdLarger) = UserIdUtil.OrderUserIds(userId, friendId);

        await dbContext.Friendships.AddAsync(new Friendship { UserId = userIdSmaller, FriendId = userIdLarger }, cancellation);
    }

    private async Task<bool> FriendshipExists(string userId, string otherUserId, CancellationToken cancellation)
    {
        var (userIdSmaller, userIdLarger) = UserIdUtil.OrderUserIds(userId, otherUserId);
        return await dbContext.Friendships.AsNoTracking()
            .AnyAsync(f => f.UserId == userIdSmaller && f.FriendId == userIdLarger, cancellation);
    }
}
