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
        return await dbContext.DailyStepEntries.AsNoTracking()
            .Where(x => x.UserId == userId && x.Date == DateOnly.FromDateTime(DateTime.Today))
            .Select(x => new GetDailyStepsResponse(x.Steps, x.Date, x.UserId))
            .ToListAsync(cancellation);

        // TODO get friends steps
        // get steps
        // TODO testa sql som genereras
        //var result = await dbContext.AppUsers
        //.Select(user => new
        //{
        //    user.UserId,
        //    user.FirstName,
        //    Steps = dbContext.DailyStepEntries
        //        .Where(e => e.UserId == user.UserId)
        //        .Select(e => new { e.Date, e.Steps })
        //        .ToList()
        //})
        //.ToListAsync();

        // bör bli
        //    SELECT
        //    u.UserId, 
        //    u.FirstName,
        //    s.Date,
        //    s.Steps
        //FROM AppUsers u
        //LEFT JOIN DailyStepEntries s ON s.UserId = u.UserId
    }
}
