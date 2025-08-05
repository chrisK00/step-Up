using System.ComponentModel.DataAnnotations;

namespace stepUp.Api.Domains.Steps;

public record AddDailyStepsRequest([Required] int Steps, string UserId);