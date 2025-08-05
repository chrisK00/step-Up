using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using stepUp.Api.Data;
using stepUp.Api.Domains.Authentication;
using stepUp.Api.Domains.Steps;
using stepUp.Api.Extensions;
using stepUp.Api.Middleware;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddScoped<ILoginService, LoginService>();

builder.Services.AddDbContext<AppDbContext>(options => options.UseSqlite("Data Source=App.db"));

FirebaseApp.Create(new AppOptions()
{
    Credential = GoogleCredential.FromFile(Path.Combine("secrets", "firebase-service-account.json"))
});

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.MigrateAsync();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseMiddleware<FirebaseAuthMiddleware>();

app.MapPost("/users", async (HttpContext context, SignUpRequest request, ILoginService loginService) =>
{
    var requestWithUserId = request with { UserId = context.GetUserId() };

    await loginService.SignUpAsync(requestWithUserId);
    return Results.CreatedAtRoute($"/users/{requestWithUserId.UserId}");
});

app.MapPost("/steps", async (HttpContext context, AddDailyStepsRequest request, ILoginService loginService) =>
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

internal record HealthCheckResponse(string Status);
