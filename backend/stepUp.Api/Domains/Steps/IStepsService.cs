using System.Threading;

namespace stepUp.Api.Domains.Steps;

public interface IStepsService
{
    public Task AddDailySteps(AddDailyStepsRequest request, CancellationToken cancellation);
    Task<IReadOnlyCollection<GetDailyStepsResponse>> GetDailySteps(string userId, CancellationToken cancellation);
}
