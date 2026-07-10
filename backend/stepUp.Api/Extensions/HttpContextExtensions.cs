using System.Security.Claims;

namespace stepUp.Api.Extensions;

public static class HttpContextExtensions
{
    public static string GetUserId(this HttpContext context) => context.User.FindFirst(ClaimTypes.NameIdentifier).Value;

    public static string GetEmail(this HttpContext context) => context.User.FindFirst(ClaimTypes.Email).Value;
}
