using Microsoft.EntityFrameworkCore;
using stepUp.Api.Data;
using stepUp.Api.Data.Entities;

namespace stepUp.Api.Domains.Steps;

public class StepsService(AppDbContext dbContext, IUnitOfWork unitOfWork) : IStepsService
{
    public async Task AddDailyStepsAsync(AddDailyStepsRequest request, CancellationToken cancellation)
    {
        var targetDate = request.Date ?? DateOnly.FromDateTime(DateTime.UtcNow);

        var existingStepEntryForToday = await dbContext.DailyStepEntries
            .SingleOrDefaultAsync(x => x.UserId == request.UserId && x.Date == targetDate, cancellation);

        if (existingStepEntryForToday != null)
        {
            existingStepEntryForToday.Steps = request.Steps;
        }
        else
        {
            var stepEntry = new DailyStepEntry { Steps = request.Steps, UserId = request.UserId, Date = targetDate };
            await dbContext.DailyStepEntries.AddAsync(stepEntry, cancellation);
        }

        await unitOfWork.SaveChangesAsync(cancellation);
    }

    public async Task BulkAddDailyStepsAsync(BulkAddDailyStepsRequest request, CancellationToken cancellation)
    {
        var distinctEntries = request.Entries
            .GroupBy(e => e.Date)
            .Select(g => g.Last())
            .ToList();

        var dates = distinctEntries.Select(e => e.Date).ToList();

        var existing = await dbContext.DailyStepEntries
            .Where(x => x.UserId == request.UserId && dates.Contains(x.Date))
            .ToListAsync(cancellation);

        var existingByDate = existing.ToDictionary(x => x.Date);

        foreach (var entry in distinctEntries)
        {
            if (existingByDate.TryGetValue(entry.Date, out var row))
            {
                row.Steps = entry.Steps;
            }
            else
            {
                await dbContext.DailyStepEntries.AddAsync(
                    new DailyStepEntry { Steps = entry.Steps, UserId = request.UserId, Date = entry.Date },
                    cancellation);
            }
        }

        await unitOfWork.SaveChangesAsync(cancellation);
    }

    public async Task<IReadOnlyCollection<GetDailyStepsResponse>> GetDailyStepsAsync(string userId, DateOnly? date, CancellationToken cancellation)
    {
        var requestedDate = date ?? DateOnly.FromDateTime(DateTime.UtcNow);

        var thumbsUpCount = await dbContext.FriendReactions.AsNoTracking()
            .CountAsync(r => r.FriendId == userId && r.Date == requestedDate, cancellation);

        var steps = await (from s in dbContext.DailyStepEntries.AsNoTracking()
                           join u in dbContext.Users.AsNoTracking()
                           on s.UserId equals u.UserId
                           where s.UserId == userId && s.Date == requestedDate
                           select new { s.Steps, s.Date, s.UserId, u.FirstName })
                          .ToListAsync(cancellation);

        return steps.Select(s => new GetDailyStepsResponse(s.Steps, s.Date, s.UserId, s.FirstName, thumbsUpCount, false)).ToList();
    }

    public async Task<IReadOnlyCollection<GetDailyStepsResponse>> GetFriendsDailyStepsAsync(string userId, DateOnly? date, CancellationToken cancellation)
    {
        var requestedDate = date ?? DateOnly.FromDateTime(DateTime.UtcNow);

        var friendIds = await dbContext.Friendships.AsNoTracking()
            .Where(f => f.UserId == userId || f.FriendId == userId)
            .Select(f => f.UserId == userId ? f.FriendId : f.UserId)
            .ToListAsync(cancellation);

        var allReactionsToday = await dbContext.FriendReactions.AsNoTracking()
            .Where(r => r.Date == requestedDate && (friendIds.Contains(r.FriendId) || r.UserId == userId))
            .ToListAsync(cancellation);

        var reactionsCountByFriend = allReactionsToday
            .Where(r => friendIds.Contains(r.FriendId))
            .GroupBy(r => r.FriendId)
            .ToDictionary(g => g.Key, g => g.Count());

        var myReactionsSet = allReactionsToday
            .Where(r => r.UserId == userId)
            .Select(r => r.FriendId)
            .ToHashSet();

        var friendsSteps = await (
            from s in dbContext.DailyStepEntries.AsNoTracking()
            join u in dbContext.Users.AsNoTracking()
                on s.UserId equals u.UserId
            where friendIds.Contains(s.UserId) && s.Date == requestedDate
            orderby s.Steps descending
            select new { s.Steps, s.Date, s.UserId, u.FirstName }
        ).ToListAsync(cancellation);

        return friendsSteps.Select(s => new GetDailyStepsResponse(
            s.Steps,
            s.Date,
            s.UserId.ToString(),
            s.FirstName,
            reactionsCountByFriend.TryGetValue(s.UserId, out var count) ? count : 0,
            myReactionsSet.Contains(s.UserId)
        )).ToList();
    }

    public async Task<IReadOnlyCollection<GetDailyStepsResponse>> GetCurrentMonthStepHistoryAsync(string userId, CancellationToken cancellation)
    {
        var now = DateTime.UtcNow;
        var startOfMonth = new DateOnly(now.Year, now.Month, 1);
        var endOfMonth = startOfMonth.AddMonths(1);

        return await (from s in dbContext.DailyStepEntries.AsNoTracking()
                      join u in dbContext.Users.AsNoTracking()
                      on s.UserId equals u.UserId
                      where s.UserId == userId && s.Date >= startOfMonth && s.Date < endOfMonth
                      orderby s.Date descending
                      select new GetDailyStepsResponse(s.Steps, s.Date, s.UserId.ToString(), u.FirstName, 0, false))
                             .ToListAsync(cancellation);
    }
}
