using stepUp.Api.Domains.Authentication;
using stepUp.Api.Domains.Steps;
using stepUp.Api.Extensions;
using stepUp.Api.Middleware;
using stepUp.Api.Utils;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddAppServices(builder.Configuration);

var app = builder.Build();

await DataSeed.SeedAsync(app.Services);

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseMiddleware<TestTokenAuthMiddleware>();
app.UseWhen(context =>
{
    var testHeader = context.Request.Headers[AuthConstants.TestTokenAuthHeader].FirstOrDefault();
    var config = context.RequestServices.GetRequiredService<IConfiguration>();

    return string.IsNullOrEmpty(testHeader) || testHeader != config[AuthConstants.ConfigTestTokenKey];
}, builder => builder.UseMiddleware<FirebaseAuthMiddleware>());

app.MapGet("health", () => Results.Ok());

app.MapPost("users", async (HttpContext context, SignUpRequest request, ILoginService loginService, CancellationToken cancellation) =>
{
    var requestWithUserId = request with { UserId = context.GetUserId(), Email = context.GetEmail() };

    try
    {
        await loginService.SignUpAsync(requestWithUserId, cancellation);
    }
    catch (UserExistsException ex)
    {

        return Results.BadRequest(ex.Message);
    }

    return Results.CreatedAtRoute($"/users/{requestWithUserId.UserId}");
});

var steps = app.MapGroup("steps");

steps.MapPost(string.Empty, async (HttpContext context, AddDailyStepsRequest request, IStepsService stepsService, CancellationToken cancellation) =>
{
    var requestWithUserId = request with { UserId = context.GetUserId() };
    await stepsService.AddDailySteps(requestWithUserId, cancellation);

    return Results.Created();
});

steps.MapGet(string.Empty, async (HttpContext context, IStepsService stepsService, CancellationToken cancellation) =>
{
    var userId = context.GetUserId();
    var dailySteps = await stepsService.GetDailySteps(userId, cancellation);

    return Results.Ok(dailySteps);
});

app.Run();
