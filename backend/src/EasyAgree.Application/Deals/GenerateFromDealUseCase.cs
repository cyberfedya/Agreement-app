using EasyAgree.Application.Common;
using EasyAgree.Application.Common.Interfaces;
using EasyAgree.Application.Templates;
using EasyAgree.Application.Deals.Interview;
using EasyAgree.Application.Documents;
using EasyAgree.Domain.Entities;
using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals;

/// <summary>
/// Finalizes a deal into a first draft. The interview deliberately asks
/// only about the agreement's object and terms, so the full required-field
/// set is assembled here from three sources, in priority order:
///   1. answers persisted on the deal (interview answers + AI-extracted
///      values from the original request) and answers sent with this call,
///   2. the creator's profile (their own party details — never asked),
///   3. the second party's profile, once they've accepted the invite via
///      <see cref="AcceptDealInviteUseCase"/> (null until then),
///   4. a visible blank placeholder for whatever's still missing (notarial
///      metadata, or a party whose profile isn't linked/filled in yet).
///
/// Profile-resolved values and placeholders are deliberately never written
/// back into <c>Deal.AnswersJson</c> - only genuine answers are - so this
/// use case can be called again later (e.g. right after the second party
/// accepts) and pick up newly-available profile data instead of being
/// stuck with whatever placeholder got persisted the first time.
/// </summary>
public sealed class GenerateFromDealUseCase(
    IDealRepository dealRepository,
    IAgreementTemplateRepository templateRepository,
    IUserProfileRepository profileRepository,
    IUploadedDocumentRepository documentRepository,
    PartyRoleClassifier roleClassifier,
    GenerateAgreementUseCase generateAgreement)
{
    private const string PendingPlaceholder = "____________";

    /// <summary>
    /// Every role pair a template might name its two parties with. A
    /// template only ever uses one of these pairs; whichever pair actually
    /// appears in its labels gets classified to find which side the
    /// creator is on. Order matters only as a tie-break when a template
    /// somehow matches more than one pair. RoleACode/RoleBCode are stable
    /// language-neutral identifiers (stored on Deal, not shown directly to
    /// users) - the invite screen is responsible for translating them.
    /// </summary>
    private static readonly (string[] RoleA, string[] RoleB, string RoleACode, string RoleBCode)[] RolePairs =
    [
        (["сотувчи", "продав"], ["сотиб олувчи", "харидор", "покупател"], "seller", "buyer"),
        (["ижарага берувчи", "арендодател"], ["ижарага олувчи", "арендатор"], "landlord", "tenant"),
        (["қарз берувчи", "займодав"], ["қарз олувчи", "заемщик", "заёмщик"], "lender", "borrower"),
        (["иш берувчи", "работодател"], ["ходим", "работник"], "employer", "employee"),
        (["буюртмачи", "заказчик"], ["пудратчи", "подрядчик", "исполнител", "бажарувчи"], "customer", "contractor"),
        (["ҳадя қилувчи", "дарител"], ["ҳадя олувчи", "одаряем"], "donor", "recipient"),
        (
            ["биринчи томон", "первой стороны", "первая сторона", "биринчи тараф"],
            ["иккинчи томон", "второй стороны", "вторая сторона", "иккинчи тараф"],
            "first_party", "second_party"
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

        if (DealPartyResponseSerializer.Deserialize(deal.PartyResponsesJson).Any(response =>
                response.Type is DealPartyResponseTypes.ProposedChange or DealPartyResponseTypes.Clarification) ||
            deal.InviteStatus is InviteStatus.ChangeRequested or InviteStatus.ClarificationRequested)
        {
            return GenerateFromDealResult.LegalReviewRequired();
        }

        var merged = DealAnswersSerializer.Deserialize(deal.AnswersJson);
        foreach (var (fieldId, value) in answers)
        {
            if (!string.IsNullOrWhiteSpace(value))
                merged[fieldId] = value;
        }

        var labels = AgreementPlaceholderParser.ExtractLabels(template.HtmlTemplate);
        // Documents are a first-class deterministic answer source. Apply the
        // mapper here as well as in the interview, so a user can upload a
        // complete document set and generate immediately without having to
        // trigger a redundant interview turn first.
        var documents = await documentRepository.GetByDealIdAsync(dealId, cancellationToken);
        if (DocumentConflictEngine.Detect(documents).Any(conflict => conflict.Severity == "HIGH"))
            return GenerateFromDealResult.LegalReviewRequired();

        var documentHints = DocumentFieldHintCollection.FromDocuments(documents);
        DocumentFieldMapper.ApplyMatches(template.Fields, labels, documentHints, merged);
        var creatorProfile = deal.ProfileId is null ? null : await profileRepository.GetAsync(deal.ProfileId, cancellationToken);
        var secondPartyProfile = deal.SecondPartyProfileId is null
            ? null
            : await profileRepository.GetAsync(deal.SecondPartyProfileId, cancellationToken);
        var roleResolution = await ResolveCreatorRoleAsync(
            labels, deal.RequestText, deal.FirstPartyRole, deal.ExpectedSecondPartyRole, cancellationToken);

        // Everything from here on is only for rendering this document -
        // never persisted back to deal.AnswersJson, so a later call (once
        // the second party's profile is linked) can freely re-resolve.
        var forRender = new Dictionary<int, string>(merged);
        foreach (var field in template.Fields)
        {
            if (field.Mode != AgreementFieldMode.Required || forRender.ContainsKey(field.FieldId))
                continue;

            var label = labels.GetValueOrDefault(field.FieldId, string.Empty);
            var resolved =
                (creatorProfile is null ? null : ResolveFromProfile(label, creatorProfile, roleResolution.CreatorKeywords))
                ?? (secondPartyProfile is null ? null : ResolveFromProfile(label, secondPartyProfile, roleResolution.SecondPartyKeywords));
            forRender[field.FieldId] = string.IsNullOrWhiteSpace(resolved) ? PendingPlaceholder : resolved;
        }

        var result = await generateAgreement.ExecuteAsync(deal.TemplateKey, forRender, cancellationToken);
        if (result.IsNotFound)
            return GenerateFromDealResult.NotFound();
        if (result.MissingFieldIds is { Count: > 0 })
            return GenerateFromDealResult.MissingFields(result.MissingFieldIds);

        deal.AnswersJson = DealAnswersSerializer.Serialize(merged);
        deal.GeneratedHtml = result.Html;
        // A regenerate (e.g. after the second party accepts) must never
        // regress a deal that's already fully signed back to "just
        // generated".
        if (deal.Status != DealStatus.FullySigned)
            deal.Status = DealStatus.Completed;
        deal.FirstPartyRole = roleResolution.CreatorRoleCode;
        deal.ExpectedSecondPartyRole = roleResolution.SecondPartyRoleCode;
        deal.UpdatedAt = DateTime.UtcNow;
        await dealRepository.UpdateAsync(deal, cancellationToken);

        return GenerateFromDealResult.Success(result.Html!);
    }

    private sealed record RoleResolution(
        string[] CreatorKeywords, string[] SecondPartyKeywords, string? CreatorRoleCode, string? SecondPartyRoleCode);

    /// <summary>
    /// Finds which role-pair (if any) this template's field labels use,
    /// and asks <see cref="PartyRoleClassifier"/> which side the creator
    /// is on. Returns the keyword set for each side, so
    /// <see cref="ResolveFromProfile"/> only fills the role each person
    /// actually occupies - not always the role hardcoded as "first"
    /// regardless of what the creator said - plus the stable role codes
    /// for both sides, persisted on the deal for the invite endpoint.
    ///
    /// When a role has already been persisted from an earlier generate
    /// call, it's reused as-is instead of asking the classifier again:
    /// <see cref="PartyRoleClassifier"/> is LLM-backed and not guaranteed
    /// to answer identically on every call, and re-classifying on the
    /// regenerate that happens right after the second party accepts the
    /// invite could silently swap which role's keywords their profile
    /// gets matched against - making a correctly-linked second-party
    /// profile fail to render at all.
    /// </summary>
    private async Task<RoleResolution> ResolveCreatorRoleAsync(
        IReadOnlyDictionary<int, string> labels, string? requestText,
        string? persistedCreatorRoleCode, string? persistedSecondPartyRoleCode, CancellationToken cancellationToken)
    {
        if (persistedCreatorRoleCode is not null)
        {
            foreach (var (roleA, roleB, roleACode, roleBCode) in RolePairs)
            {
                if (roleACode == persistedCreatorRoleCode && roleBCode == persistedSecondPartyRoleCode)
                    return new RoleResolution(roleA, roleB, roleACode, roleBCode);
                if (roleBCode == persistedCreatorRoleCode && roleACode == persistedSecondPartyRoleCode)
                    return new RoleResolution(roleB, roleA, roleBCode, roleACode);
            }
        }

        var allLabels = string.Join(' ', labels.Values).ToLowerInvariant();

        foreach (var (roleA, roleB, roleACode, roleBCode) in RolePairs)
        {
            if (!roleA.Any(allLabels.Contains) || !roleB.Any(allLabels.Contains))
                continue;

            var creatorIsA = await roleClassifier.CreatorIsRoleAAsync(requestText, roleA[0], roleB[0], cancellationToken);
            return creatorIsA
                ? new RoleResolution(roleA, roleB, roleACode, roleBCode)
                : new RoleResolution(roleB, roleA, roleBCode, roleACode);
        }

        return new RoleResolution(FallbackCreatorKeywords, [], null, null);
    }

    /// <summary>
    /// Maps a party field label to the corresponding profile value, or
    /// null when the field belongs to someone else (notary, or the other
    /// party) or names an attribute the profile doesn't carry.
    /// </summary>
    private static string? ResolveFromProfile(string label, UserProfile profile, string[] roleKeywords)
    {
        var lower = label.ToLowerInvariant();
        if (roleKeywords.Length == 0 || !roleKeywords.Any(lower.Contains))
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
