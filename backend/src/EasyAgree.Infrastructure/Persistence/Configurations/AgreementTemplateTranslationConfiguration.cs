using EasyAgree.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EasyAgree.Infrastructure.Persistence.Configurations;

public sealed class AgreementTemplateTranslationConfiguration : IEntityTypeConfiguration<AgreementTemplateTranslation>
{
    public void Configure(EntityTypeBuilder<AgreementTemplateTranslation> builder)
    {
        builder.ToTable("agreement_template_translations");

        builder.HasKey(t => t.Id);

        builder.Property(t => t.Language)
            .IsRequired()
            .HasMaxLength(10);

        builder.Property(t => t.Title)
            .IsRequired()
            .HasMaxLength(1000);

        builder.Property(t => t.Description)
            .IsRequired()
            .HasColumnType("text");

        builder.HasIndex(t => new { t.AgreementTemplateId, t.Language }).IsUnique();
    }
}
