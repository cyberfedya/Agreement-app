using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace EasyAgree.Infrastructure.Persistence.Repositories;

public sealed class AgreementTemplateRepository(EasyAgreeDbContext db) : IAgreementTemplateRepository
{
    public async Task<IReadOnlyList<AgreementTemplate>> GetActiveAsync(CancellationToken cancellationToken = default) =>
        await db.AgreementTemplates
            .Where(t => t.IsActive)
            .Include(t => t.Translations)
            .OrderBy(t => t.Domain)
            .ThenBy(t => t.Key)
            .AsNoTracking()
            .ToListAsync(cancellationToken);

    public async Task<AgreementTemplate?> GetByKeyAsync(string key, CancellationToken cancellationToken = default) =>
        await db.AgreementTemplates
            .Include(t => t.Translations)
            .Include(t => t.Fields)
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Key == key, cancellationToken);
}
