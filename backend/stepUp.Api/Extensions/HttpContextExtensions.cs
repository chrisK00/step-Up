using System.Security.Claims;

namespace stepUp.Api.Extensions;

public static class HttpContextExtensions
{
    public static string GetUserId(this HttpContext context)
    {
        return context.User.FindFirst(ClaimTypes.NameIdentifier).Value;
    }
}
