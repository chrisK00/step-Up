using Microsoft.EntityFrameworkCore;
using stepUp.Api.Data;
using stepUp.Api.Data.Entities;

namespace stepUp.Api.Domains.Steps;

public class StepsService(AppDbContext dbContext, IUnitOfWork unitOfWork) : IStepsService
{
    public async Task AddDailySteps(AddDailyStepsRequest request, CancellationToken cancellation)
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

    public async Task<IReadOnlyCollection<GetDailyStepsResponse>> GetDailySteps(string userId, CancellationToken cancellation)
    {
        var today = DateOnly.FromDateTime(DateTime.Today);

        // TODO get friends steps instead of just current userid
        return await (from s in dbContext.DailyStepEntries.AsNoTracking()
                      join u in dbContext.Users.AsNoTracking()
                      on s.UserId equals u.UserId
                      where s.UserId == userId && s.Date == today
                      select new GetDailyStepsResponse(s.Steps, s.Date, s.UserId, u.FirstName))
                            .ToListAsync(cancellation);
    }
}
