namespace EasyAgree.Contracts.Deals;

public sealed record AgreementValidationIssueDto(
    string Code,
    string Severity,
    int? FieldId,
    string? Label,
    string Message,
    string RecommendedAction);

public sealed record AgreementValidationDto(bool IsValid, IReadOnlyList<AgreementValidationIssueDto> Issues);
