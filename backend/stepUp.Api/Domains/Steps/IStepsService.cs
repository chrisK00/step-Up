using System.Threading;

namespace stepUp.Api.Domains.Steps;

public interface IStepsService
{
    public Task AddDailyStepsAsync(AddDailyStepsRequest request, CancellationToken cancellation);
    Task<IReadOnlyCollection<GetDailyStepsResponse>> GetDailyStepsAsync(string userId, CancellationToken cancellation);
    Task<IReadOnlyCollection<GetDailyStepsResponse>> GetFriendsDailyStepsAsync(string userId, CancellationToken cancellation);
}
