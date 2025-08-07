using FirebaseAdmin.Auth;
using System.Security.Claims;

namespace stepUp.Api.Middleware;

public class FirebaseAuthMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context)
    {
        string? authHeader = context.Request.Headers.Authorization;

        if (string.IsNullOrEmpty(authHeader))
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsync("Missing auth token");
            return;
        }

        try
        {
            var decodedToken = await FirebaseAuth.DefaultInstance.VerifyIdTokenAsync(authHeader);
            var claims = new List<Claim>
                {
                   new(ClaimTypes.NameIdentifier, decodedToken.Uid),
                };

            context.User = new ClaimsPrincipal(new ClaimsIdentity(claims));
        }
        catch
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsync("Invalid auth token");
            return;
        }

        await next(context);
    }
}
