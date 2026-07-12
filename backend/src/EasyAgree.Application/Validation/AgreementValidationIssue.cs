namespace EasyAgree.Application.Validation;

public sealed record AgreementValidationIssue(
    string Code,
    string Severity,
    int? FieldId,
    string? Label,
    string Message,
    string RecommendedAction);

public sealed record AgreementValidationResult(bool IsValid, IReadOnlyList<AgreementValidationIssue> Issues);
