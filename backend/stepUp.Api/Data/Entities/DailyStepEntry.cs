using System.ComponentModel.DataAnnotations;

namespace stepUp.Api.Data.Entities;

public class DailyStepEntry
{
    [Key]
    public int Id { get; set; }

    public int Steps { get; set; }
    public DateOnly Date { get; set; } = DateOnly.FromDateTime(DateTime.Today);

    [Required]
    public string UserId { get; set; }
}
