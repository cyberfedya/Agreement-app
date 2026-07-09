using EasyAgree.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace EasyAgree.Infrastructure.Persistence.Configurations;

public sealed class UserProfileConfiguration : IEntityTypeConfiguration<UserProfile>
{
    public void Configure(EntityTypeBuilder<UserProfile> builder)
    {
        builder.ToTable("user_profiles");

        builder.HasKey(p => p.Id);
        builder.Property(p => p.Id).HasMaxLength(64);

        builder.Property(p => p.FullName).HasMaxLength(300);
        builder.Property(p => p.PassportNumber).HasMaxLength(50);
        builder.Property(p => p.BirthDate).HasMaxLength(20);
        builder.Property(p => p.Address).HasMaxLength(500);

        builder.Property(p => p.UpdatedAt);
    }
}
