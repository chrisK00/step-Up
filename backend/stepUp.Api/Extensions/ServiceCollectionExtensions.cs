using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using stepUp.Api.Data;
using stepUp.Api.Domains.Authentication;
using stepUp.Api.Domains.FriendRequests;
using stepUp.Api.Domains.Friendships;
using stepUp.Api.Domains.Steps;
using stepUp.Api.Domains.Users;
using stepUp.Api.Utils;

namespace stepUp.Api.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddAppServices(this IServiceCollection services, IConfiguration config)
    {
        if (string.IsNullOrWhiteSpace(config[AuthConstants.ConfigTestTokenKey]))
        {
            throw new ApplicationException($"Missing required {AuthConstants.ConfigTestTokenKey} in configuration");
        }

        services.AddEndpointsApiExplorer();
        services.AddSwaggerGen();

        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped<ILoginService, LoginService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IStepsService, StepsService>();
        services.AddScoped<IFriendRequestService, FriendRequestService>();
        services.AddScoped<IFriendshipService, FriendshipService>();

        services.AddDbContext<AppDbContext>(options =>
        {
            options.UseSqlite($"Data Source={Path.Combine(AppContext.BaseDirectory, "App.db")}");
#if DEBUG
            options.EnableSensitiveDataLogging();
            options.LogTo(Console.WriteLine, LogLevel.Information);
#endif
        });

        FirebaseApp.Create(new AppOptions()
        {
            Credential = GoogleCredential.FromFile(Path.Combine("secrets", "firebase-service-account.json"))
        });

        return services;
    }
}
