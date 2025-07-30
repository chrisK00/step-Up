using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using stepUp.Api.Domains.Authentication;
using stepUp.Api.Middleware;
using System.Security.Claims;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddScoped<ILoginService, LoginService>();

FirebaseApp.Create(new AppOptions()
{
    Credential = GoogleCredential.FromFile(Path.Combine("secrets", "firebase-service-account.json"))
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseMiddleware<FirebaseAuthMiddleware>();

app.MapPost("/users", async (HttpContext context, SignUpRequest request, ILoginService loginService) =>
{
    var requestWithUserId = request with { UserId = context.User.FindFirst(ClaimTypes.NameIdentifier).Value };

    await loginService.SignUpAsync(requestWithUserId);
    return Results.CreatedAtRoute($"/users/{requestWithUserId.UserId}");
});

app.Run();

internal record HealthCheckResponse(string Status);
