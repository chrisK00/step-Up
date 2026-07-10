using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace stepUp.Api.Data.Entities;

[Index(nameof(FirstName), IsUnique = true)]
public class AppUser
{
    [Key]
    public string UserId { get; set; }

    [Required]
    public string FirstName { get; set; }

    [Required]
    public string Email { get; set; }
}
