using EasyAgree.Domain.Entities;

namespace EasyAgree.Application.Deals;

public sealed record PartyRoleResolution(
    string[] CreatorKeywords, string[] SecondPartyKeywords, string? CreatorRoleCode, string? SecondPartyRoleCode);

/// <summary>
/// Maps a template's party-role labels (seller/buyer, landlord/tenant, ...)
/// to whichever side the deal's creator actually is, and resolves an
/// identity-attribute field label (name/address/passport/...) to the right
/// profile's value for that side. Shared by <see cref="GenerateFromDealUseCase"/>
/// (final render) and <see cref="GetDealFieldStatesUseCase"/> (live
/// preview/review, before generation) so both agree on what's known.
/// </summary>
public sealed class PartyProfileResolver(PartyRoleClassifier roleClassifier)
{
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
    public async Task<PartyRoleResolution> ResolveRoleAsync(
        IReadOnlyDictionary<int, string> labels, string? requestText,
        string? persistedCreatorRoleCode, string? persistedSecondPartyRoleCode, CancellationToken cancellationToken)
    {
        if (persistedCreatorRoleCode is not null)
        {
            foreach (var (roleA, roleB, roleACode, roleBCode) in RolePairs)
            {
                if (roleACode == persistedCreatorRoleCode && roleBCode == persistedSecondPartyRoleCode)
                    return new PartyRoleResolution(roleA, roleB, roleACode, roleBCode);
                if (roleBCode == persistedCreatorRoleCode && roleACode == persistedSecondPartyRoleCode)
                    return new PartyRoleResolution(roleB, roleA, roleBCode, roleACode);
            }
        }

        var allLabels = string.Join(' ', labels.Values).ToLowerInvariant();

        foreach (var (roleA, roleB, roleACode, roleBCode) in RolePairs)
        {
            if (!roleA.Any(allLabels.Contains) || !roleB.Any(allLabels.Contains))
                continue;

            var creatorIsA = await roleClassifier.CreatorIsRoleAAsync(requestText, roleA[0], roleB[0], cancellationToken);
            return creatorIsA
                ? new PartyRoleResolution(roleA, roleB, roleACode, roleBCode)
                : new PartyRoleResolution(roleB, roleA, roleBCode, roleACode);
        }

        return new PartyRoleResolution(FallbackCreatorKeywords, [], null, null);
    }

    /// <summary>
    /// Maps a party field label to the corresponding profile value, or
    /// null when the field belongs to someone else (notary, or the other
    /// party) or names an attribute the profile doesn't carry.
    /// </summary>
    public static string? ResolveFromProfile(string label, UserProfile profile, string[] roleKeywords)
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
        if (lower.Contains("паспорт берган") || lower.Contains("паспорт берилган"))
            return null;
        if (lower.Contains("паспорт"))
            return profile.PassportNumber;

        return null;
    }
}
