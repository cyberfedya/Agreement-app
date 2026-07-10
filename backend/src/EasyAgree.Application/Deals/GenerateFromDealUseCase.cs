using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Templates;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals;

/// <summary>
/// Finalizes a deal into a first draft. The interview deliberately asks
/// only about the agreement's object and terms, so the full required-field
/// set is assembled here from four sources, in priority order:
///   1. answers persisted on the deal (interview answers + AI-extracted
///      values from the original request),
///   2. answers sent by the client with this call,
///   3. the creator's profile (their own party details — never asked;
///      blank if the creator hasn't filled in their profile yet),
///   4. a visible blank placeholder for everything still pending: the
///      second party's details (filled via the QR-sign flow) and notarial
///      metadata (filled at the notarization stage).
/// </summary>
public sealed class GenerateFromDealUseCase(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository,
    IUserProfileRepository profileRepository,
    PartyRoleClassifier roleClassifier,
    GenerateAgreementUseCase generateAgreement)
{
    private const string PendingPlaceholder = "____________";

    /// <summary>
    /// Every role pair a template might name its two parties with. A
    /// template only ever uses one of these pairs; whichever pair actually
    /// appears in its labels gets classified to find which side the
    /// creator is on. Order matters only as a tie-break when a template
    /// somehow matches more than one pair.
    /// </summary>
    private static readonly (string[] RoleA, string[] RoleB)[] RolePairs =
    [
        (["сотувчи", "продав"], ["сотиб олувчи", "харидор", "покупател"]),
        (["ижарага берувчи", "арендодател"], ["ижарага олувчи", "арендатор"]),
        (["қарз берувчи", "займодав"], ["қарз олувчи", "заемщик", "заёмщик"]),
        (["иш берувчи", "работодател"], ["ходим", "работник"]),
        (["буюртмачи", "заказчик"], ["пудратчи", "подрядчик", "исполнител", "бажарувчи"]),
        (["ҳадя қилувчи", "дарител"], ["ҳадя олувчи", "одаряем"]),
        (
            ["биринчи томон", "первой стороны", "первая сторона", "биринчи тараф"],
            ["иккинчи томон", "второй стороны", "вторая сторона", "иккинчи тараф"]
        ),
    ];

    /// <summary>Fallback when no role pair from the list above matches this template's labels at all.</summary>
    private static readonly string[] FallbackCreatorKeywords =
        ["аризачи", "даъвогар", "талабнома берувчи"];

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
        var profile = deal.ProfileId is null ? null : await profileRepository.GetAsync(deal.ProfileId, cancellationToken);
        var creatorKeywords = await ResolveCreatorKeywordsAsync(labels, deal.RequestText, cancellationToken);

        foreach (var field in template.Fields)
        {
            if (field.Mode != AgreementFieldMode.Required || merged.ContainsKey(field.FieldId))
                continue;

            var label = labels.GetValueOrDefault(field.FieldId, string.Empty);
            var resolved = profile is null ? null : ResolveFromProfile(label, profile, creatorKeywords);
            merged[field.FieldId] = string.IsNullOrWhiteSpace(resolved) ? PendingPlaceholder : resolved;
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
    /// Finds which role-pair (if any) this template's field labels use,
    /// and asks <see cref="PartyRoleClassifier"/> which side the creator
    /// is on. Returns the keyword set for that side, so
    /// <see cref="ResolveFromProfile"/> only fills the role the creator
    /// actually described themselves as - not always the role hardcoded
    /// as "first" regardless of what they said.
    /// </summary>
    private async Task<string[]> ResolveCreatorKeywordsAsync(
        IReadOnlyDictionary<int, string> labels, string? requestText, CancellationToken cancellationToken)
    {
        var allLabels = string.Join(' ', labels.Values).ToLowerInvariant();

        foreach (var (roleA, roleB) in RolePairs)
        {
            if (!roleA.Any(allLabels.Contains) || !roleB.Any(allLabels.Contains))
                continue;

            var creatorIsA = await roleClassifier.CreatorIsRoleAAsync(requestText, roleA[0], roleB[0], cancellationToken);
            return creatorIsA ? roleA : roleB;
        }

        return FallbackCreatorKeywords;
    }

    /// <summary>
    /// Maps a creator-party field label to the corresponding profile value,
    /// or null when the field belongs to someone else (second party,
    /// notary) or names an attribute the profile doesn't carry.
    /// </summary>
    private static string? ResolveFromProfile(string label, UserProfile profile, string[] creatorKeywords)
    {
        var lower = label.ToLowerInvariant();
        if (!creatorKeywords.Any(lower.Contains))
            return null;

        if (lower.Contains("ф.и.о") || lower.Contains("фио"))
            return profile.FullName;
        if (lower.Contains("манзил") || lower.Contains("адрес"))
            return profile.Address;
        if (lower.Contains("туғилган") || lower.Contains("рожден"))
            return profile.BirthDate;

        // "паспорт берган"/"паспорт берилган" (who issued it / when it was
        // issued) are NOT the passport number - UserProfile doesn't carry
        // either, so these must fall through to null (blank placeholder)
        // rather than matching the broader "паспорт" check below and
        // getting the number stamped into the wrong field.
        if (lower.Contains("паспорт берган") || lower.Contains("паспорт берилган"))
            return null;
        if (lower.Contains("паспорт"))
            return profile.PassportNumber;

        return null;
    }
}
