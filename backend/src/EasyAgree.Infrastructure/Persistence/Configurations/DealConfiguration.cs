using EasyAgree.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EasyAgree.Infrastructure.Persistence.Configurations;

public sealed class DealConfiguration : IEntityTypeConfiguration<Deal>
{
    public void Configure(EntityTypeBuilder<Deal> builder)
    {
        builder.ToTable("deals");

        builder.HasKey(d => d.Id);

        builder.Property(d => d.TemplateKey)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(d => d.RequestText)
            .HasColumnType("text");

        builder.Property(d => d.Status)
            .HasConversion<string>()
            .HasMaxLength(20);

        builder.Property(d => d.GeneratedHtml)
            .HasColumnType("text");

        builder.Property(d => d.CreatedAt);
        builder.Property(d => d.UpdatedAt);

        builder.HasIndex(d => d.TemplateKey);
    }
}
