using Microsoft.EntityFrameworkCore;
using stepUp.Api.Data;
using stepUp.Api.Data.Entities;

namespace stepUp.Api.Utils;

public static class DataSeed
{
    public static async Task SeedAsync(IServiceProvider serviceProvider)
    {
        using var scope = serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        await db.Database.MigrateAsync();

        if (db.Users.Any())
        {
            return;
        }

        await db.Users.AddAsync(new AppUser { Email = "test@mail.com", FirstName = "test", UserId = AuthConstants.TestUserId });
        await db.SaveChangesAsync();
    }
}
