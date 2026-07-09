using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Templates;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals;

/// <summary>
/// Finalizes a deal into a first draft. The interview deliberately asks
/// only about the agreement's object and terms, so the full required-field
/// set is assembled here from four sources, in priority order:
///   1. answers persisted on the deal (interview answers + AI-extracted
///      values from the original request),
///   2. answers sent by the client with this call,
///   3. the creator's profile (their own party details — never asked),
///   4. a visible blank placeholder for everything still pending: the
///      second party's details (filled via the QR-sign flow) and notarial
///      metadata (filled at the notarization stage).
/// </summary>
public sealed class GenerateFromDealUseCase(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository,
    IUserProfileProvider profileProvider,
    GenerateAgreementUseCase generateAgreement)
{
    private const string PendingPlaceholder = "____________";

    /// <summary>Field labels naming the deal's first party — the role the creator plays.</summary>
    private static readonly string[] CreatorPartyKeywords =
    [
        "сотувчи", "продав",
        "ижарага берувчи", "арендодател",
        "қарз берувчи", "займодав", "кредитор",
        "иш берувчи", "работодател",
        "буюртмачи", "заказчик",
        "ҳадя қилувчи", "дарител",
        "аризачи", "даъвогар", "талабнома берувчи",
        // generic wording some templates use instead of role names
        "биринчи томон", "первой стороны", "первая сторона", "биринчи тараф",
    ];

    public async Task<GenerateFromDealResult> ExecuteAsync(
        Guid dealId, IReadOnlyDictionary<int, string> answers, CancellationToken cancellationToken = default)
    {
        var deal = await dealRepository.GetByIdAsync(dealId, cancellationToken);
        if (deal is null)
            return GenerateFromDealResult.NotFound();

        var template = await templateRepository.GetByKeyAsync(deal.TemplateKey, cancellationToken);
        if (template is null)
            return GenerateFromDealResult.NotFound();
        var merged = DealAnswersSerializer.Deserialize(deal.AnswersJson);
        foreach (var (fieldId, value) in answers)
        {
            if (!string.IsNullOrWhiteSpace(value))
                merged[fieldId] = value;
        }

        var labels = AgreementPlaceholderParser.ExtractLabels(template.HtmlTemplate);
        var profile = await profileProvider.GetCurrentAsync(cancellationToken);

        foreach (var field in template.Fields)
        {
            if (field.Mode != AgreementFieldMode.Required || merged.ContainsKey(field.FieldId))
                continue;

            var label = labels.GetValueOrDefault(field.FieldId, string.Empty);
            merged[field.FieldId] = ResolveFromProfile(label, profile) ?? PendingPlaceholder;
        }

        var result = await generateAgreement.ExecuteAsync(deal.TemplateKey, merged, cancellationToken);
        if (result.IsNotFound)
            return GenerateFromDealResult.NotFound();
        if (result.MissingFieldIds is { Count: > 0 })
            return GenerateFromDealResult.MissingFields(result.MissingFieldIds);

        deal.AnswersJson = DealAnswersSerializer.Serialize(merged);
        deal.GeneratedHtml = result.Html;
        deal.Status = DealStatus.Completed;
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);

        return GenerateFromDealResult.Success(result.Html!);
    }

    /// <summary>
    /// Maps a creator-party field label to the corresponding profile value,
    /// or null when the field belongs to someone else (second party,
    /// notary) or names an attribute the profile doesn't carry.
    /// </summary>
    private static string? ResolveFromProfile(string label, UserProfile profile)
    {
        var lower = label.ToLowerInvariant();
        if (!CreatorPartyKeywords.Any(lower.Contains))
            return null;

        if (lower.Contains("ф.и.о") || lower.Contains("фио"))
            return profile.FullName;
        if (lower.Contains("манзил") || lower.Contains("адрес"))
            return profile.Address;
        if (lower.Contains("туғилган") || lower.Contains("рожден"))
            return profile.BirthDate;
        if (lower.Contains("паспорт"))
        {
            if (lower.Contains("берилган сана") || lower.Contains("дата выдачи"))
                return profile.PassportIssueDate;
            if (lower.Contains("берган") || lower.Contains("выдав"))
                return profile.PassportIssuedBy;
            return profile.PassportNumber;
        }

        return null;
    }
}
