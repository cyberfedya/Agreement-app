using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace EasyAgree.Infrastructure.Persistence.Repositories;

public sealed class UserProfileRepository(EasyAgreeDbContext db) : IUserProfileRepository
{
    public async Task<UserProfile?> GetAsync(string id, CancellationToken cancellationToken = default) =>
        await db.UserProfiles.AsNoTracking().FirstOrDefaultAsync(p => p.Id == id, cancellationToken);

    public async Task<UserProfile> UpsertAsync(UserProfile profile, CancellationToken cancellationToken = default)
    {
        var existing = await db.UserProfiles.FirstOrDefaultAsync(p => p.Id == profile.Id, cancellationToken);
        if (existing is null)
        {
            db.UserProfiles.Add(profile);
        }
        else
        {
            existing.FullName = profile.FullName;
            existing.PassportNumber = profile.PassportNumber;
            existing.BirthDate = profile.BirthDate;
            existing.Address = profile.Address;
            existing.UpdatedAt = profile.UpdatedAt;
        }

        await db.SaveChangesAsync(cancellationToken);
        return existing ?? profile;
    }

    public async Task DeleteAsync(string id, CancellationToken cancellationToken = default)
    {
        var existing = await db.UserProfiles.FirstOrDefaultAsync(p => p.Id == id, cancellationToken);
        if (existing is null)
            return;

        db.UserProfiles.Remove(existing);
        await db.SaveChangesAsync(cancellationToken);
    }
}
