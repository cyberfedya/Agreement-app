namespace EasyAgree.Contracts.Documents;

public sealed record DocumentConflictValueDto(Guid DocumentId, string FileName, string Value, double Confidence, string Source);
public sealed record DocumentConflictDto(
    string Type,
    string Field,
    string Severity,
    string Reason,
    string RecommendedResolution,
    IReadOnlyList<DocumentConflictValueDto> Values);
