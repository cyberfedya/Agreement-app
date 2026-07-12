using EasyAgree.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EasyAgree.Infrastructure.Persistence.Configurations;

public sealed class UploadedDocumentConfiguration : IEntityTypeConfiguration<UploadedDocument>
{
    public void Configure(EntityTypeBuilder<UploadedDocument> builder)
    {
        builder.ToTable("uploaded_documents");

        builder.HasKey(d => d.Id);

        builder.Property(d => d.FileName)
            .IsRequired()
            .HasMaxLength(300);

        builder.Property(d => d.ContentType)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(d => d.StoragePath)
            .IsRequired()
            .HasMaxLength(500);

        builder.Property(d => d.DocumentType)
            .HasConversion<string>()
            .HasMaxLength(50);

        builder.Property(d => d.ExtractedFieldsJson)
            .HasColumnType("jsonb");

        builder.Property(d => d.NormalizedFieldsJson)
            .HasColumnType("jsonb");

        builder.Property(d => d.OcrText)
            .HasColumnType("text");

        builder.Property(d => d.Status)
            .HasConversion<string>()
            .HasMaxLength(20);

        builder.Property(d => d.ErrorMessage)
            .HasColumnType("text");

        builder.Property(d => d.MismatchWarning)
            .HasColumnType("text");

        builder.HasIndex(d => d.DealId);
    }
}
