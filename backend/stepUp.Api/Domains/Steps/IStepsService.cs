namespace stepUp.Api.Domains.Steps;

public interface IStepsService
{
    Task AddDailyStepsAsync(AddDailyStepsRequest request, CancellationToken cancellation);
    Task BulkAddDailyStepsAsync(BulkAddDailyStepsRequest request, CancellationToken cancellation);
    Task<IReadOnlyCollection<GetDailyStepsResponse>> GetDailyStepsAsync(string userId, DateOnly? date, CancellationToken cancellation);
    Task<IReadOnlyCollection<GetDailyStepsResponse>> GetFriendsDailyStepsAsync(string userId, DateOnly? date, CancellationToken cancellation);
    Task<IReadOnlyCollection<GetDailyStepsResponse>> GetCurrentMonthStepHistoryAsync(string userId, CancellationToken cancellation);
}
