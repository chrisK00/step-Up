using Microsoft.EntityFrameworkCore;
using stepUp.Api.Data.Entities;

namespace stepUp.Api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<AppUser> Users { get; set; }
    public DbSet<DailyStepEntry> DailyStepEntries { get; set; }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<DailyStepEntry>()
            .HasOne<AppUser>()
            .WithMany()
            .HasForeignKey(x => x.UserId);

        builder.Entity<DailyStepEntry>()
            .HasIndex(x => x.Date);

        builder.Entity<DailyStepEntry>()
            .HasIndex(x => new { x.UserId, x.Date })
            .IsUnique();
    }
}
