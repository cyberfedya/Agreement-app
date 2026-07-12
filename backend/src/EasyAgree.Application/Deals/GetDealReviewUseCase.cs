using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;

namespace EasyAgree.Application.Deals;

public sealed record DealReviewField(
    int FieldId,
    string Label,
    string? Value,
    string Source,
    double Confidence,
    string Status,
    string Reason);

public sealed record DealReviewResult(
    IReadOnlyList<DealReviewField> AutoFilled,
    IReadOnlyList<DealReviewField> Manual,
    IReadOnlyList<DealReviewField> Corrected,
    IReadOnlyList<DealReviewField> Missing,
    IReadOnlyList<DealReviewField> Skipped);

/// <summary>Read-only, deterministic pre-generation state. It deliberately
/// performs no LLM calls and does not mutate a deal.</summary>
public sealed class GetDealReviewUseCase(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository,
    IUploadedDocumentRepository documentRepository)
{
    public async Task<DealReviewResult?> ExecuteAsync(Guid dealId, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return null;

        var template = await templateRepository.GetByKeyAsync(deal.TemplateKey, cancellationToken);
        if (template is null)
            return null;

        var labels = AgreementPlaceholderParser.ExtractLabels(template.HtmlTemplate);
        var answers = DealAnswersSerializer.Deserialize(deal.AnswersJson);
        var hints = DocumentFieldHintCollection.FromDocuments(await documentRepository.GetByDealIdAsync(dealId, cancellationToken));
        var mapped = DocumentFieldMapper.FindMatches(template.Fields, labels, hints, answers.Keys)
            .ToDictionary(mapping => mapping.FieldId);

        var autoFilled = new List<DealReviewField>();
        var manual = new List<DealReviewField>();
        var corrected = new List<DealReviewField>();
        var missing = new List<DealReviewField>();
        var skipped = new List<DealReviewField>();

        foreach (var field in FieldEligibilityEngine.Classify(template.Fields, labels))
        {
            if (answers.TryGetValue(field.FieldId, out var answer))
            {
                manual.Add(new(field.FieldId, field.Label, answer, "manual", 1.0, "CONFIRMED", "Recorded interview answer"));
                continue;
            }

            if (mapped.TryGetValue(field.FieldId, out var mapping))
            {
                var target = string.Equals(mapping.Source, "user_override", StringComparison.OrdinalIgnoreCase)
                    ? corrected
                    : autoFilled;
                var status = target == corrected ? "CORRECTED" : "AUTO_FILLED";
                target.Add(new(field.FieldId, field.Label, mapping.Value, mapping.Source, mapping.Confidence, status,
                    $"Mapped from document field {string.Join(", ", mapping.HintKeys)}"));
                continue;
            }

            if (field.Category == FieldCategory.NeverAsk)
                skipped.Add(new(field.FieldId, field.Label, null, "system", 1.0, "LOCKED", "Profile, QR, or document metadata field"));
            else if (FieldDependencyEngine.IsObsolete(field, answers, labels))
                skipped.Add(new(field.FieldId, field.Label, null, "system", 1.0, "LOCKED", "Obsolete because a dependency answer made it irrelevant"));
            else if (field.Category is FieldCategory.RequiredObject or FieldCategory.RequiredCommercial or FieldCategory.RequiredTime)
                missing.Add(new(field.FieldId, field.Label, null, "unknown", 0, "UNKNOWN", "No trusted value available"));
        }

        return new DealReviewResult(autoFilled, manual, corrected, missing, skipped);
    }
}
