namespace EasyAgree.Infrastructure.Persistence.Seed.Models;

/// <summary>Summary of a single seeder run, used for logging/observability.</summary>
public sealed class AgreementSeedResult
{
    public int TotalFilesScanned { get; set; }

    public int Imported { get; set; }

    public int Updated { get; set; }

    public int Skipped { get; set; }

    public int Errors { get; set; }

    public int TotalTemplatesInDatabase { get; set; }

    public TimeSpan Elapsed { get; set; }
}
