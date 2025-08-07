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

app.MapPost("users", async (HttpContext context, SignUpRequest request, ILoginService loginService) =>
{
    var requestWithUserId = request with { UserId = context.GetUserId() };

    await loginService.SignUpAsync(requestWithUserId);
    return Results.CreatedAtRoute($"/users/{requestWithUserId.UserId}");
});

app.MapPost("steps", async (HttpContext context, AddDailyStepsRequest request, ILoginService loginService) =>
{
    var requestWithUserId = request with { UserId = context.GetUserId() };

    //await loginService.SignUpAsync(requestWithUserId);
    //return Results.CreatedAtRoute($"/users/{requestWithUserId.UserId}");

    // TODO testa sql som genereras

    //var result = await dbContext.AppUsers
    //.Select(user => new
    //{
    //    user.UserId,
    //    user.FirstName,
    //    Steps = dbContext.DailyStepEntries
    //        .Where(e => e.UserId == user.UserId)
    //        .Select(e => new { e.Date, e.Steps })
    //        .ToList()
    //})
    //.ToListAsync();

    // bör bli
    //    SELECT
    //    u.UserId, 
    //    u.FirstName,
    //    s.Date,
    //    s.Steps
    //FROM AppUsers u
    //LEFT JOIN DailyStepEntries s ON s.UserId = u.UserId

});

app.Run();
