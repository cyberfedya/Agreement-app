using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace EasyAgree.Infrastructure.Persistence.Repositories;

public sealed class UploadedDocumentRepository(EasyAgreeDbContext db) : IUploadedDocumentRepository
{
    public async Task<UploadedDocument> AddAsync(UploadedDocument document, CancellationToken cancellationToken = default)
    {
        db.UploadedDocuments.Add(document);
        await db.SaveChangesAsync(cancellationToken);
        return document;
    }

    public async Task<UploadedDocument?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default) =>
        await db.UploadedDocuments.FirstOrDefaultAsync(d => d.Id == id, cancellationToken);

    public async Task<List<UploadedDocument>> GetByDealIdAsync(Guid dealId, CancellationToken cancellationToken = default) =>
        await db.UploadedDocuments
            .Where(d => d.DealId == dealId)
            .OrderBy(d => d.UploadedAt)
            .ToListAsync(cancellationToken);

    public async Task UpdateAsync(UploadedDocument document, CancellationToken cancellationToken = default)
    {
        db.UploadedDocuments.Update(document);
        await db.SaveChangesAsync(cancellationToken);
    }

    public async Task DeleteAsync(UploadedDocument document, CancellationToken cancellationToken = default)
    {
        db.UploadedDocuments.Remove(document);
        await db.SaveChangesAsync(cancellationToken);
    }
}
