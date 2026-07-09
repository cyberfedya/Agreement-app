using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals;

namespace EasyAgree.Application.Documents;

public sealed class IntakePreprocessingService(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository,
    IUploadedDocumentRepository documentRepository,
    IUserProfileRepository profileRepository,
    IFieldMergeService fieldMergeService)
{
    public async Task RefreshAsync(Guid dealId, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return;

        var template = await templateRepository.GetByKeyAsync(deal.TemplateKey, cancellationToken);
        if (template is null)
            return;

        var labels = AgreementPlaceholderParser.ExtractLabels(template.HtmlTemplate);
        var answers = DealAnswersSerializer.Deserialize(deal.AnswersJson);
        var previous = MergedFieldCollectionSerializer.Deserialize(deal.PreprocessedFieldsJson);
        previous.RemoveOwnedAnswers(answers);

        var documents = await documentRepository.GetByDealIdAsync(dealId, cancellationToken);
        var profile = deal.ProfileId is null ? null : await profileRepository.GetAsync(deal.ProfileId, cancellationToken);
        var refreshed = await fieldMergeService.BuildAsync(
            template.Fields, labels, answers, documents, profile, cancellationToken);

        refreshed.ApplyHighConfidenceAnswers(answers);
        deal.AnswersJson = DealAnswersSerializer.Serialize(answers);
        deal.PreprocessedFieldsJson = MergedFieldCollectionSerializer.Serialize(refreshed);
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);
    }
}
