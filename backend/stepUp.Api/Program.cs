using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using stepUp.Api;
using stepUp.Api.Domains.Authentication;
using stepUp.Api.Domains.FriendRequests;
using stepUp.Api.Domains.Friendships;
using stepUp.Api.Domains.Steps;
using stepUp.Api.Domains.Users;
using stepUp.Api.Extensions;
using stepUp.Api.Middleware;
using stepUp.Api.Utils;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.Converters.Add(new JsonStringEnumConverter());
    options.SerializerOptions.Converters.Add(new DateOnlyJsonConverter());
});
builder.Services.Configure<JsonOptions>(options =>
{
    options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    options.JsonSerializerOptions.Converters.Add(new DateOnlyJsonConverter());
});

builder.Logging.AddConsole();
builder.Configuration.AddEnvironmentVariables();

builder.Services.AddAppServices(builder.Configuration);

var app = builder.Build();

await DataSeed.SeedAsync(app.Services);

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

//app.UseHttpsRedirection();

app.UseMiddleware<TestTokenAuthMiddleware>();
app.UseWhen(context =>
{
    var testHeader = context.Request.Headers[AuthConstants.TestTokenAuthHeader].FirstOrDefault();
    var config = context.RequestServices.GetRequiredService<IConfiguration>();

    return string.IsNullOrEmpty(testHeader) || testHeader != config[AuthConstants.ConfigTestTokenKey];
}, builder => builder.UseMiddleware<FirebaseAuthMiddleware>());

app.MapGet("health", () => Results.Ok()).WithTags("Misc");

var users = app.MapGroup("users")
    .WithTags("Users");

users.MapPost(string.Empty, async ([FromBody(EmptyBodyBehavior = EmptyBodyBehavior.Disallow)] SignUpRequest request, HttpContext context, ILoginService loginService, CancellationToken cancellation) =>
{
    var requestWithUserId = request with { UserId = context.GetUserId(), Email = context.GetEmail() };

    try
    {
        await loginService.SignUpAsync(requestWithUserId, cancellation);
    }
    // TODO result instead, expected exception tbh
    catch (UserExistsException ex)
    {
        return TypedResults.BadRequest(ex.Message);
    }

    return Results.Created($"/users/{requestWithUserId.UserId}", requestWithUserId.UserId);
}).WithParameterValidation();

users.MapGet(string.Empty, async ([FromQuery, Required] string username, IUserService userService, CancellationToken cancellation) =>
{
    var request = new SearchUsersRequest(username);
    var users = await userService.SearchUsersAsync(request, cancellation);
    return TypedResults.Ok(users);
}).WithParameterValidation();

var steps = app.MapGroup("steps")
    .WithTags("Steps"); ;

steps.MapPost(string.Empty, async ([FromBody(EmptyBodyBehavior = EmptyBodyBehavior.Disallow)] AddDailyStepsRequest request, HttpContext context, IStepsService stepsService, CancellationToken cancellation) =>
{
    var requestWithUserId = request with { UserId = context.GetUserId() };
    await stepsService.AddDailyStepsAsync(requestWithUserId, cancellation);

    return Results.Created();
}).WithParameterValidation();

steps.MapPost("bulk", async ([FromBody(EmptyBodyBehavior = EmptyBodyBehavior.Disallow)] BulkAddDailyStepsRequest request, HttpContext context, IStepsService stepsService, CancellationToken cancellation) =>
{
    var requestWithUserId = request with { UserId = context.GetUserId() };
    await stepsService.BulkAddDailyStepsAsync(requestWithUserId, cancellation);

    return Results.Created();
}).WithParameterValidation();

steps.MapGet(string.Empty, async ([FromQuery] DateOnly? date, HttpContext context, IStepsService stepsService, CancellationToken cancellation) =>
{
    var dailySteps = await stepsService.GetDailyStepsAsync(context.GetUserId(), date, cancellation);

    return TypedResults.Ok(dailySteps);
});

steps.MapGet("friends", async ([FromQuery] DateOnly? date, HttpContext context, IStepsService stepsService, CancellationToken cancellation) =>
{
    var dailySteps = await stepsService.GetFriendsDailyStepsAsync(context.GetUserId(), date, cancellation);

    return TypedResults.Ok(dailySteps);
});

steps.MapGet("history", async (HttpContext context, IStepsService stepsService, CancellationToken cancellation) =>
{
    var dailySteps = await stepsService.GetCurrentMonthStepHistoryAsync(context.GetUserId(), cancellation);

    return TypedResults.Ok(dailySteps);
});

var friendRequests = app.MapGroup("friend-requests")
    .WithTags("Friend Requests");
friendRequests.MapPost(string.Empty, async ([FromBody(EmptyBodyBehavior = EmptyBodyBehavior.Disallow)] SendFriendRequest request, HttpContext context, IFriendRequestService friendRequestService, CancellationToken cancellation) =>
{
    var requestWithUserId = request with { UserId = context.GetUserId() };
    var result = await friendRequestService.SendFriendRequestAsync(requestWithUserId, cancellation);

    return result.Success ? Results.Created() : TypedResults.BadRequest(result.Error);
}).WithParameterValidation();

friendRequests.MapGet(string.Empty, async ([FromQuery] FriendRequestType friendRequestType, HttpContext context, IFriendRequestService friendRequestService, CancellationToken cancellation) =>
{
    var requestWithUserId = new GetFriendRequests(context.GetUserId(), friendRequestType);
    var friendRequests = await friendRequestService.GetFriendRequestsAsync(requestWithUserId, cancellation);

    return TypedResults.Ok(friendRequests);
}).WithParameterValidation();

friendRequests.MapPost("accept", async (AcceptFriendRequest request, HttpContext context, IFriendRequestService friendRequestService, CancellationToken cancellation) =>
{
    var requestWithUserId = request with { UserId = context.GetUserId() };
    var result = await friendRequestService.AcceptFriendRequestAsync(requestWithUserId, cancellation);

    return result.Success ? Results.Created() : TypedResults.BadRequest(result.Error);
}).WithParameterValidation();

friendRequests.MapDelete("{otherUserId}", async ([Required(AllowEmptyStrings = false)] string otherUserId, HttpContext context, IFriendRequestService friendRequestService, CancellationToken cancellation) =>
{
    // TODO mb just use a scoped userservice that caches in scope the userid
    var requestWithUserId = new DeleteFriendRequest(context.GetUserId(), otherUserId);
    var result = await friendRequestService.DeleteFriendRequestAsync(requestWithUserId, cancellation);

    return result.Success ? Results.NoContent() : TypedResults.BadRequest(result.Error);
}).WithParameterValidation();

var friends = app.MapGroup("friends")
    .WithTags("Friends");

friends.MapGet(string.Empty, async (HttpContext context, IFriendshipService friendshipService, CancellationToken cancellation) =>
{
    var friendships = await friendshipService.GetFriendshipsAsync(context.GetUserId(), cancellation);

    return TypedResults.Ok(friendships);
});

friends.MapDelete("{friendId}", async (string friendId, HttpContext context, IFriendshipService friendshipService, CancellationToken cancellation) =>
{
    var requestWithUserId = new DeleteFriendshipRequest(context.GetUserId(), friendId);
    var result = await friendshipService.DeleteFriendshipAsync(requestWithUserId, cancellation);

    return result.Success ? Results.NoContent() : TypedResults.BadRequest(result.Error);
}).WithParameterValidation();

friends.MapPost("reactions/thumbs-up", async ([FromBody(EmptyBodyBehavior = EmptyBodyBehavior.Disallow)] SendFriendReactionRequest request, HttpContext context, IFriendshipService friendshipService, CancellationToken cancellation) =>
{
    var requestWithUserId = request with { UserId = context.GetUserId() };
    var result = await friendshipService.SendThumbsUpAsync(requestWithUserId, cancellation);

    return result.Success ? Results.Created() : TypedResults.BadRequest(result.Error);
}).WithParameterValidation();

friends.MapGet("reactions/received", async (HttpContext context, IFriendshipService friendshipService, CancellationToken cancellation) =>
{
    var reactions = await friendshipService.GetReceivedReactionsAsync(context.GetUserId(), cancellation);
    return TypedResults.Ok(reactions);
});

app.Run();
