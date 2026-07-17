namespace EasyAgree.Contracts.Templates;

/// <param name="AcceptedAt">Set once the second party has accepted the invite - null until then.</param>
public sealed record GenerateAgreementResponse(
    string Key,
    string Html,
    DateTime GeneratedAt,
    string? SecondPartyName = null,
    string? FirstPartyName = null,
    DateTime? FirstPartySignedAt = null,
    DateTime? SecondPartySignedAt = null,
    bool IsFullySigned = false,
    DateTime? AcceptedAt = null,
    string? FirstPartyRole = null,
    string? SecondPartyRole = null,
    string? TemplateDomain = null);
