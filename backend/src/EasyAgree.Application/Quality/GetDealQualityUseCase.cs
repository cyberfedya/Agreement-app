using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;

namespace EasyAgree.Application.Quality;

public sealed class GetDealQualityUseCase(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository,
    IUploadedDocumentRepository documentRepository)
{
    public async Task<AgreementQualityScore?> ExecuteAsync(Guid dealId, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null) return null;
        var template = await templateRepository.GetByKeyAsync(deal.TemplateKey, cancellationToken);
        if (template is null) return null;

        var labels = AgreementPlaceholderParser.ExtractLabels(template.HtmlTemplate);
        var answers = DealAnswersSerializer.Deserialize(deal.AnswersJson);
        var documents = await documentRepository.GetByDealIdAsync(dealId, cancellationToken);
        var hints = DocumentFieldHintCollection.FromDocuments(documents);
        var mapped = DocumentFieldMapper.FindMatches(template.Fields, labels, hints, answers.Keys).Select(m => m.FieldId).ToHashSet();

        // Same eligibility rule the interview itself uses: technical
        // characteristics (FieldCategory.DocumentOnly) are never asked and
        // must never count toward "required" here either - a missing
        // engine number must not lower the readiness score when no
        // document was ever expected to be uploaded.
        var required = FieldEligibilityEngine.Classify(template.Fields, labels)
            .Where(field => field.Category is FieldCategory.RequiredObject or FieldCategory.RequiredCommercial or FieldCategory.RequiredTime)
            .ToList();
        var manual = required.Count(field => answers.ContainsKey(field.FieldId));
        var automatic = required.Count(field => !answers.ContainsKey(field.FieldId) && mapped.Contains(field.FieldId));
        var missing = required
            .Where(field => !answers.ContainsKey(field.FieldId) && !mapped.Contains(field.FieldId))
            .Select(field => field.Label)
            .ToList();

        return AgreementQualityScoreEngine.Calculate(required.Count, manual, automatic, hints.Fields,
            DocumentConflictEngine.Detect(documents), missing);
    }
}
