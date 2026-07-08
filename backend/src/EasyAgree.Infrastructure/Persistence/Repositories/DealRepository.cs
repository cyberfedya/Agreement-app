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
}
