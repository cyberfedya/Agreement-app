using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Application.Documents;

public sealed class IntakePreprocessingService(
    IDealRepository dealRepository,
    IUploadedDocumentRepository documentRepository,
    IUserProfileRepository profileRepository)
{
    public async Task RefreshAsync(Guid dealId, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return;

        var documents = await documentRepository.GetByDealIdAsync(dealId, cancellationToken);
        var profile = deal.ProfileId is null ? null : await profileRepository.GetAsync(deal.ProfileId, cancellationToken);
        var refreshed = DocumentFieldHintCollection.Combine(
            DocumentFieldHintCollection.FromDocuments(documents),
            DocumentFieldHintCollection.FromProfile(profile));

        deal.PreprocessedFieldsJson = DocumentFieldHintCollectionSerializer.Serialize(refreshed);
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);
    }
}
