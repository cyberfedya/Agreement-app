using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace EasyAgree.Infrastructure.Persistence;

/// <summary>
/// Lets `dotnet ef migrations` run against this project directly (e.g. CI, or
/// when the API host's own DI graph isn't available), independent of Program.cs.
/// </summary>
public sealed class EasyAgreeDbContextFactory : IDesignTimeDbContextFactory<EasyAgreeDbContext>
{
    public EasyAgreeDbContext CreateDbContext(string[] args)
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__Default")
            ?? "Host=localhost;Database=easyagree;Username=easyagree;Password=easyagree";

        var optionsBuilder = new DbContextOptionsBuilder<EasyAgreeDbContext>();
        optionsBuilder.UseNpgsql(connectionString, npgsql =>
            npgsql.MigrationsAssembly(typeof(EasyAgreeDbContext).Assembly.FullName));

        return new EasyAgreeDbContext(optionsBuilder.Options);
    }
}
