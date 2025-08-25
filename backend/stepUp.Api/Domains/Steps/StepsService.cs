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

    public async Task<IReadOnlyCollection<GetDailyStepsResponse>> GetDailyStepsAsync(string userId, CancellationToken cancellation)
    {
        var today = DateOnly.FromDateTime(DateTime.Today);

        return await (from s in dbContext.DailyStepEntries.AsNoTracking()
                      join u in dbContext.Users.AsNoTracking()
                      on s.UserId equals u.UserId
                      where s.UserId == userId && s.Date == today
                      select new GetDailyStepsResponse(s.Steps, s.Date, s.UserId, u.FirstName))
                            .ToListAsync(cancellation);
    }

    public async Task<IReadOnlyCollection<GetDailyStepsResponse>> GetFriendsDailyStepsAsync(string userId, CancellationToken cancellation)
    {
        var today = DateOnly.FromDateTime(DateTime.Today);

        var friendsSteps = await (
            from f in dbContext.Friendships.AsNoTracking()
            let friendId = f.UserId == userId ? f.FriendId : f.UserId
            join s in dbContext.DailyStepEntries.AsNoTracking()
                on friendId equals s.UserId
            join u in dbContext.Users.AsNoTracking()
                on friendId equals u.UserId
            where (f.UserId == userId || f.FriendId == userId) && s.Date == today
            select new GetDailyStepsResponse(s.Steps, s.Date, s.UserId.ToString(), u.FirstName)
        ).ToListAsync(cancellation);

        return friendsSteps;
    }
}
