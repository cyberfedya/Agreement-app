using EasyAgree.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EasyAgree.Infrastructure.Persistence.Configurations;

public sealed class AgreementTemplateFieldConfiguration : IEntityTypeConfiguration<AgreementTemplateField>
{
    public void Configure(EntityTypeBuilder<AgreementTemplateField> builder)
    {
        builder.ToTable("agreement_template_fields");

        builder.HasKey(f => f.Id);

        builder.Property(f => f.FieldId)
            .IsRequired();

        builder.Property(f => f.Mode)
            .HasConversion<string>()
            .HasMaxLength(20)
            .HasDefaultValue(Domain.Enums.AgreementFieldMode.Required);

        builder.HasIndex(f => new { f.AgreementTemplateId, f.FieldId }).IsUnique();
    }
}
