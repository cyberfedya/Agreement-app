using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Domain.Enums;

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

        var required = template.Fields
            .Where(field => field.Mode == AgreementFieldMode.Required)
            .Select(field => (field.FieldId, labels.GetValueOrDefault(field.FieldId, $"field #{field.FieldId}")))
            .ToList();
        return AgreementValidationEngine.Validate(required, answers, DocumentConflictEngine.Detect(documents));
    }
}
