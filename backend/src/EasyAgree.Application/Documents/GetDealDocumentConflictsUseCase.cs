using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Application.Documents;

public sealed class GetDealDocumentConflictsUseCase(
    IDealRepository dealRepository,
    IUploadedDocumentRepository documentRepository)
{
    public async Task<IReadOnlyList<DocumentConflict>?> ExecuteAsync(Guid dealId, CancellationToken cancellationToken = default)
    {
        if (await dealRepository.GetByIdAsync(dealId, cancellationToken) is null)
            return null;
        return DocumentConflictEngine.Detect(await documentRepository.GetByDealIdAsync(dealId, cancellationToken));
    }
}
