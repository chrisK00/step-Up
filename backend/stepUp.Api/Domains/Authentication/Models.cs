using System.ComponentModel.DataAnnotations;

namespace stepUp.Api.Domains.Authentication;

public record SignUpRequest(string UserId, [Required, EmailAddress] string Email, [Required] string FirstName);