using Microsoft.AspNetCore.Mvc;
using stepUp.Api.Domains.Authentication;
using stepUp.Api.Domains.FriendRequests;
using stepUp.Api.Domains.Friendships;
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

app.MapGet("health", () => Results.Ok()).WithTags("Misc");

app.MapPost("users", async (SignUpRequest request, HttpContext context, ILoginService loginService, CancellationToken cancellation) =>
{
    var requestWithUserId = request with { UserId = context.GetUserId(), Email = context.GetEmail() };

    try
    {
        await loginService.SignUpAsync(requestWithUserId, cancellation);
    }
    // TODO result instead, expected exception tbh
    catch (UserExistsException ex)
    {

        return Results.BadRequest(ex.Message);
    }

    return Results.CreatedAtRoute($"/users/{requestWithUserId.UserId}");
})
    .WithTags("Users");

var steps = app.MapGroup("steps")
    .WithTags("Steps"); ;

steps.MapPost(string.Empty, async (AddDailyStepsRequest request, HttpContext context, IStepsService stepsService, CancellationToken cancellation) =>
{
    var requestWithUserId = request with { UserId = context.GetUserId() };
    await stepsService.AddDailyStepsAsync(requestWithUserId, cancellation);

    return Results.Created();
});

steps.MapGet(string.Empty, async (HttpContext context, IStepsService stepsService, CancellationToken cancellation) =>
{
    var dailySteps = await stepsService.GetDailyStepsAsync(context.GetUserId(), cancellation);

    return Results.Ok(dailySteps);
});

steps.MapGet("friends", async (HttpContext context, IStepsService stepsService, CancellationToken cancellation) =>
{
    var dailySteps = await stepsService.GetFriendsDailyStepsAsync(context.GetUserId(), cancellation);

    return Results.Ok(dailySteps);
});

var friendRequests = app.MapGroup("friend-requests")
    .WithTags("Friend Requests"); ;
friendRequests.MapPost(string.Empty, async (SendFriendRequest request, HttpContext context, IFriendRequestService friendRequestService, CancellationToken cancellation) =>
{
    var requestWithUserId = request with { UserId = context.GetUserId() };
    var result = await friendRequestService.SendFriendRequestAsync(requestWithUserId, cancellation);

    return result.Success ? Results.Created() : Results.BadRequest(result.Error);
});

friendRequests.MapGet(string.Empty, async ([FromQuery] FriendRequestType friendRequestType, HttpContext context, IFriendRequestService friendRequestService, CancellationToken cancellation) =>
{
    var requestWithUserId = new GetFriendRequests(context.GetUserId(), friendRequestType);
    var friendRequests = await friendRequestService.GetFriendRequestsAsync(requestWithUserId, cancellation);

    return Results.Ok(friendRequests);
});

friendRequests.MapPost("accept", async (AcceptFriendRequest request, HttpContext context, IFriendRequestService friendRequestService, CancellationToken cancellation) =>
{
    var requestWithUserId = request with { UserId = context.GetUserId() };
    var result = await friendRequestService.AcceptFriendRequestAsync(requestWithUserId, cancellation);

    return result.Success ? Results.Created() : Results.BadRequest(result.Error);
});

friendRequests.MapDelete(string.Empty, async ([Guid] string otherUserId, HttpContext context, IFriendRequestService friendRequestService, CancellationToken cancellation) =>
{
    var requestWithUserId = new DeleteFriendRequest(context.GetUserId(), otherUserId);
    var result = await friendRequestService.DeleteFriendRequestAsync(requestWithUserId, cancellation);

    return result.Success ? Results.NoContent() : Results.BadRequest(result.Error);
});

var friends = app.MapGroup("friends")
    .WithTags("Friends");

friends.MapGet(string.Empty, async (HttpContext context, IFriendshipService friendshipService, CancellationToken cancellation) =>
{
    var friendships = await friendshipService.GetFriendshipsAsync(context.GetUserId(), cancellation);

    return Results.Ok(friendships);
});

friends.MapDelete(string.Empty, async (string friendId, HttpContext context, IFriendshipService friendshipService, CancellationToken cancellation) =>
{
    var requestWithUserId = new DeleteFriendshipRequest(context.GetUserId(), friendId);
    var result = await friendshipService.DeleteFriendshipAsync(requestWithUserId, cancellation);

    return result.Success ? Results.NoContent() : Results.BadRequest(result.Error);
});

// TODO testa endpoints + validations

app.Run();
