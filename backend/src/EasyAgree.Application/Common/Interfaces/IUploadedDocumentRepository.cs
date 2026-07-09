using EasyAgree.Domain.Entities;

namespace EasyAgree.Application.Common.Interfaces;

public interface IUploadedDocumentRepository
{
    Task<UploadedDocument> AddAsync(UploadedDocument document, CancellationToken cancellationToken = default);

    Task<UploadedDocument?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task<List<UploadedDocument>> GetByDealIdAsync(Guid dealId, CancellationToken cancellationToken = default);

    Task UpdateAsync(UploadedDocument document, CancellationToken cancellationToken = default);
}
