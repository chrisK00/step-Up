using System.ComponentModel.DataAnnotations;

namespace stepUp.Api.Domains.Steps;

public record AddDailyStepsRequest([Required] int Steps, string UserId);
public record GetDailyStepsResponse(int Steps, DateOnly Date, string UserId, string FirstName, int ThumbsUpCount = 0); // TODO change firstName to userName
