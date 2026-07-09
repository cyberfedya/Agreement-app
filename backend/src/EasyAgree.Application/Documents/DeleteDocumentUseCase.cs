using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Application.Documents;

public sealed class DeleteDocumentUseCase(
    IUploadedDocumentRepository documentRepository,
    IFileStorage fileStorage,
    IntakePreprocessingService preprocessingService)
{
    public async Task<bool> ExecuteAsync(Guid dealId, Guid documentId, CancellationToken cancellationToken = default)
    {
        var document = await documentRepository.GetByIdAsync(documentId, cancellationToken);
        if (document is null || document.DealId != dealId)
            return false;

        await fileStorage.DeleteAsync(document.StoragePath, cancellationToken);
        await documentRepository.DeleteAsync(document, cancellationToken);
        await preprocessingService.RefreshAsync(dealId, cancellationToken);
        return true;
    }
}
