using stepUp.Api.Utils;
using System.Security.Claims;

namespace stepUp.Api.Middleware;

public class TestTokenAuthMiddleware(RequestDelegate next, IConfiguration config)
{
    public async Task InvokeAsync(HttpContext context)
    {
        var testHeader = context.Request.Headers[AuthConstants.TestTokenAuthHeader].FirstOrDefault();

        if (!string.IsNullOrEmpty(testHeader))
        {
            var testToken = config[AuthConstants.TestTokenAuthHeader];
            if (testHeader != testToken)
            {
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                await context.Response.WriteAsync("Invalid test token");
                return;
            }

            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, AuthConstants.TestUserId),
            };

            context.User = new ClaimsPrincipal(new ClaimsIdentity(claims));
        }

        await next(context);
    }
}
