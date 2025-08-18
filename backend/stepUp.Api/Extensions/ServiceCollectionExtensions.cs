using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using stepUp.Api.Data;
using stepUp.Api.Domains.Authentication;
using stepUp.Api.Domains.Steps;
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
        services.AddScoped<IStepsService, StepsService>();

        services.AddDbContext<AppDbContext>(options =>
        {
            options.UseSqlite("Data Source=App.db");
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
