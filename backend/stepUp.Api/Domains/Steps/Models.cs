using System.ComponentModel.DataAnnotations;

namespace stepUp.Api.Domains.Steps;

public record AddDailyStepsRequest([Required] int Steps, string UserId, DateOnly? Date = null);
public record BulkStepEntry([Required] int Steps, [Required] DateOnly Date);
public record BulkAddDailyStepsRequest(string UserId, [Required] List<BulkStepEntry> Entries);
public record GetDailyStepsResponse(int Steps, DateOnly Date, string UserId, string FirstName, int ThumbsUpCount = 0, bool HasSentThumbsUp = false); // TODO change firstName to userName
