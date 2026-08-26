using Microsoft.EntityFrameworkCore;
using stepUp.Api.Data;
using stepUp.Api.Data.Entities;

namespace stepUp.Api.Domains.Steps;

public class StepsService(AppDbContext dbContext, IUnitOfWork unitOfWork) : IStepsService
{
    public async Task AddDailyStepsAsync(AddDailyStepsRequest request, CancellationToken cancellation)
    {
        var existingStepEntryForToday = await dbContext.DailyStepEntries
            .SingleOrDefaultAsync(x => x.UserId == request.UserId && x.Date == DateOnly.FromDateTime(DateTime.Today), cancellation);

        if (existingStepEntryForToday != null)
        {
            existingStepEntryForToday.Steps = request.Steps;
        }
        else
        {
            var stepEntry = new DailyStepEntry { Steps = request.Steps, UserId = request.UserId };
            await dbContext.DailyStepEntries.AddAsync(stepEntry, cancellation);
        }

        await unitOfWork.SaveChangesAsync(cancellation);
    }

    public async Task<IReadOnlyCollection<GetDailyStepsResponse>> GetDailyStepsAsync(string userId, DateOnly? date, CancellationToken cancellation)
    {
        var requestedDate = date ?? DateOnly.FromDateTime(DateTime.Today);
        var normalizedUserId = userId.Trim().ToLower();

        var thumbsUpCount = await dbContext.FriendReactions.AsNoTracking()
            .CountAsync(r => r.FriendId.ToLower() == normalizedUserId && r.Date == requestedDate, cancellation);

        var entries = await (from s in dbContext.DailyStepEntries.AsNoTracking()
                      join u in dbContext.Users.AsNoTracking()
                      on s.UserId.ToLower() equals u.UserId.ToLower() into users
                      from u in users.DefaultIfEmpty()
                      where s.UserId.ToLower() == normalizedUserId && s.Date == requestedDate
                      select new { s.Steps, s.Date, s.UserId, FirstName = u != null ? u.FirstName : "You" })
                            .ToListAsync(cancellation);

        return entries.Select(e => new GetDailyStepsResponse(e.Steps, e.Date, e.UserId, e.FirstName, thumbsUpCount)).ToList();
    }

    public async Task<IReadOnlyCollection<GetDailyStepsResponse>> GetFriendsDailyStepsAsync(string userId, DateOnly? date, CancellationToken cancellation)
    {
        var requestedDate = date ?? DateOnly.FromDateTime(DateTime.Today);
        var normalizedUserId = userId.Trim().ToLower();

        var friendIds = await dbContext.Friendships.AsNoTracking()
            .Where(f => f.UserId.ToLower() == normalizedUserId || f.FriendId.ToLower() == normalizedUserId)
            .Select(f => f.UserId.ToLower() == normalizedUserId ? f.FriendId : f.UserId)
            .ToListAsync(cancellation);

        var friendIdsLower = friendIds.Select(id => id.ToLower()).ToHashSet();

        var reactionsByFriend = (await dbContext.FriendReactions.AsNoTracking()
            .Where(r => r.Date == requestedDate)
            .Select(r => r.FriendId.ToLower())
            .ToListAsync(cancellation))
            .Where(friendId => friendIdsLower.Contains(friendId))
            .GroupBy(id => id)
            .ToDictionary(g => g.Key, g => g.Count());

        var entries = await (
            from s in dbContext.DailyStepEntries.AsNoTracking()
            join u in dbContext.Users.AsNoTracking()
                on s.UserId.ToLower() equals u.UserId.ToLower() into users
            from u in users.DefaultIfEmpty()
            where s.Date == requestedDate
            orderby s.Steps descending
            select new { s.Steps, s.Date, s.UserId, FirstName = u != null ? u.FirstName : "Friend" }
        ).ToListAsync(cancellation);

        return entries
            .Where(e => friendIdsLower.Contains(e.UserId.ToLower()))
            .Select(e => new GetDailyStepsResponse(
                e.Steps,
                e.Date,
                e.UserId,
                e.FirstName,
                reactionsByFriend.TryGetValue(e.UserId.ToLower(), out var count) ? count : 0
            )).ToList();
    }

    public async Task<IReadOnlyCollection<GetDailyStepsResponse>> GetCurrentMonthStepHistoryAsync(string userId, CancellationToken cancellation)
    {
        var now = DateTime.Today;
        var startOfMonth = new DateOnly(now.Year, now.Month, 1);
        var endOfMonth = startOfMonth.AddMonths(1);

        return await (from s in dbContext.DailyStepEntries.AsNoTracking()
                      join u in dbContext.Users.AsNoTracking()
                      on s.UserId equals u.UserId
                      where s.UserId == userId && s.Date >= startOfMonth && s.Date < endOfMonth
                      orderby s.Date descending
                      select new GetDailyStepsResponse(s.Steps, s.Date, s.UserId.ToString(), u.FirstName, 0))
                             .ToListAsync(cancellation);
    }
}
