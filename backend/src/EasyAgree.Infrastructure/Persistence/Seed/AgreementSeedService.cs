using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace EasyAgree.Infrastructure.Persistence.Seed;

/// <summary>
/// Startup orchestrator: applies pending EF Core migrations, then runs the
/// agreement seeder. Call this once from Program.cs (from a scope) before the
/// app starts accepting requests — templates must already be in PostgreSQL by
/// then, since the app never reads agreement JSON files at runtime.
/// </summary>
public sealed class AgreementSeedService(
    EasyAgreeDbContext db,
    AgreementSeeder seeder,
    IOptions<AgreementSeederOptions> options,
    ILogger<AgreementSeedService> logger)
{
    public async Task RunAsync(CancellationToken cancellationToken = default)
    {
        if (!options.Value.Enabled)
        {
            logger.LogInformation("Agreement seeder is disabled via configuration; skipping.");
            return;
        }

        logger.LogInformation("Applying pending database migrations...");
        await db.Database.MigrateAsync(cancellationToken);
        logger.LogInformation("Database migrations applied successfully.");

        await seeder.SeedAsync(cancellationToken);
    }
}
