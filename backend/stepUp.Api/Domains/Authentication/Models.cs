using System.ComponentModel.DataAnnotations;

namespace stepUp.Api.Domains.Authentication;

public record SignUpRequest(string UserId, string Email, [Required] string FirstName);