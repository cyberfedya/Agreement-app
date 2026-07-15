using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace EasyAgree.Infrastructure.Persistence.Repositories;

public sealed class DealRepository(EasyAgreeDbContext db) : IDealRepository
{
    public async Task<Deal> AddAsync(Deal deal, CancellationToken cancellationToken = default)
    {
        db.Deals.Add(deal);
        await db.SaveChangesAsync(cancellationToken);
        return deal;
    }

    public async Task<Deal?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        await db.Deals.FirstOrDefaultAsync(d => d.Id == id, cancellationToken);

    public async Task UpdateAsync(Deal deal, CancellationToken cancellationToken = default)
    {
        db.Deals.Update(deal);
        await db.SaveChangesAsync(cancellationToken);
    }

    public async Task<(IReadOnlyList<Deal> Items, int TotalCount)> GetByProfileIdAsync(
        string profileId, int skip, int take, CancellationToken cancellationToken = default)
    {
        var query = db.Deals.Where(d => d.ProfileId == profileId || d.SecondPartyProfileId == profileId);

        var totalCount = await query.CountAsync(cancellationToken);
        var items = await query
            .OrderByDescending(d => d.UpdatedAt)
            .Skip(skip)
            .Take(take)
            .ToListAsync(cancellationToken);

        return (items, totalCount);
    }
}
