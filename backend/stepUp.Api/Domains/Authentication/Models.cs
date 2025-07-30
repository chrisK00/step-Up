using System.ComponentModel.DataAnnotations;

namespace stepUp.Api.Domains.Authentication;

public record SignUpRequest(string UserId, [Required] string Email, [Required] string FirstName);