using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Domain.Entities;

namespace EasyAgree.Application.Documents;

public sealed class GetDealDocumentsUseCase(IUploadedDocumentRepository documentRepository)
{
    public Task<List<UploadedDocument>> ExecuteAsync(Guid dealId, CancellationToken cancellationToken = default) =>
        documentRepository.GetByDealIdAsync(dealId, cancellationToken);
}
