using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;

namespace EasyAgree.Application.Validation;

public sealed class GetDealAgreementValidationUseCase(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository,
    IUploadedDocumentRepository documentRepository)
{
    public async Task<AgreementValidationResult?> ExecuteAsync(Guid dealId, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null) return null;
        var template = await templateRepository.GetByKeyAsync(deal.TemplateKey, cancellationToken);
        if (template is null) return null;

        var labels = AgreementPlaceholderParser.ExtractLabels(template.HtmlTemplate);
        var answers = DealAnswersSerializer.Deserialize(deal.AnswersJson);
        var documents = await documentRepository.GetByDealIdAsync(dealId, cancellationToken);
        var hints = DocumentFieldHintCollection.FromDocuments(documents);
        DocumentFieldMapper.ApplyMatches(template.Fields, labels, hints, answers);

        // Same eligibility rule the interview itself uses: technical
        // characteristics (FieldCategory.DocumentOnly) are never asked and
        // must never count as "required" here either - a missing engine
        // number must not fail validation or read as a risk when no
        // document was ever expected to be uploaded.
        var required = FieldEligibilityEngine.Classify(template.Fields, labels)
            .Where(field => field.Category is FieldCategory.RequiredObject or FieldCategory.RequiredCommercial or FieldCategory.RequiredTime)
            .Select(field => (field.FieldId, field.Label))
            .ToList();
        return AgreementValidationEngine.Validate(required, answers, DocumentConflictEngine.Detect(documents));
    }
}
