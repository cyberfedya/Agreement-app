using EasyAgree.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EasyAgree.Infrastructure.Persistence.Configurations;

public sealed class AgreementTemplateConfiguration : IEntityTypeConfiguration<AgreementTemplate>
{
    public void Configure(EntityTypeBuilder<AgreementTemplate> builder)
    {
        builder.ToTable("agreement_templates");

        builder.HasKey(t => t.Id);

        builder.Property(t => t.Domain)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(t => t.Key)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(t => t.SourceUrl)
            .HasMaxLength(1000);

        builder.Property(t => t.HtmlTemplate)
            .IsRequired()
            .HasColumnType("text");

        builder.Property(t => t.IsActive)
            .HasDefaultValue(true);

        builder.Property(t => t.Version)
            .HasDefaultValue(1);

        builder.Property(t => t.CreatedAt);
        builder.Property(t => t.UpdatedAt);

        builder.HasIndex(t => t.Key).IsUnique();
        builder.HasIndex(t => t.Domain);

        builder.HasMany(t => t.Translations)
            .WithOne(t => t.AgreementTemplate)
            .HasForeignKey(t => t.AgreementTemplateId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(t => t.Fields)
            .WithOne(f => f.AgreementTemplate)
            .HasForeignKey(f => f.AgreementTemplateId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
