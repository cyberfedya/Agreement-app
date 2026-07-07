using EasyAgree.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace EasyAgree.Infrastructure.Persistence;

public class EasyAgreeDbContext(DbContextOptions<EasyAgreeDbContext> options) : DbContext(options)
{
    public DbSet<AgreementTemplate> AgreementTemplates => Set<AgreementTemplate>();

    public DbSet<AgreementTemplateTranslation> AgreementTemplateTranslations => Set<AgreementTemplateTranslation>();

    public DbSet<AgreementTemplateField> AgreementTemplateFields => Set<AgreementTemplateField>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(EasyAgreeDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }
}
