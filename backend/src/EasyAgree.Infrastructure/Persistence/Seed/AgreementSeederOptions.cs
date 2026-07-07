namespace EasyAgree.Infrastructure.Persistence.Seed;

public sealed class AgreementSeederOptions
{
    public const string SectionName = "AgreementSeeder";

    /// <summary>Set to false to skip seeding entirely (e.g. in test environments).</summary>
    public bool Enabled { get; set; } = true;

    /// <summary>
    /// Absolute or relative path to the root "agreements" folder. When empty,
    /// the seeder walks up from the app's base directory looking for a folder
    /// named "agreements" (works for local `dotnet run`). In Docker/production,
    /// set this explicitly (e.g. via AgreementSeeder__SourcePath) to a mounted path.
    /// </summary>
    public string? SourcePath { get; set; }

    /// <summary>How many templates to accumulate before calling SaveChanges.</summary>
    public int BatchSize { get; set; } = 200;
}
