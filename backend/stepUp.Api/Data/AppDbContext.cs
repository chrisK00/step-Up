using Microsoft.EntityFrameworkCore;
using stepUp.Api.Data.Entities;

namespace stepUp.Api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<AppUser> Users { get; set; }
    public DbSet<DailyStepEntry> DailyStepEntries { get; set; }
    public DbSet<FriendRequest> FriendRequests { get; set; }
    public DbSet<Friendship> Friendships { get; set; }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        ConfigureDailyStepEntry(builder);
        ConfigureFriends(builder);
    }

    private static void ConfigureDailyStepEntry(ModelBuilder builder)
    {
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

    private static void ConfigureFriends(ModelBuilder builder)
    {
        builder.Entity<FriendRequest>()
       .HasKey(f => new { f.FromUserId, f.ToUserId });

        // TODO ondelete restrict
        builder.Entity<FriendRequest>()
            .HasOne<AppUser>()
            .WithMany()
            .HasForeignKey(f => f.FromUserId);

        builder.Entity<FriendRequest>()
            .HasOne<AppUser>()
            .WithMany()
            .HasForeignKey(f => f.ToUserId);


        builder.Entity<Friendship>()
            .HasKey(f => new { f.UserId, f.FriendId });

        builder.Entity<Friendship>()
                .HasOne<AppUser>()
                .WithMany()
                .HasForeignKey(f => f.UserId);

        builder.Entity<Friendship>()
                .HasOne<AppUser>()
                .WithMany()
                .HasForeignKey(f => f.FriendId);
    }
}
