namespace EasyAgree.Application.Documents;

/// <summary>Immutable, machine-readable contradiction between independent
/// document facts. It never chooses a winner or mutates source data.</summary>
public sealed record DocumentConflict(
    string Type,
    string Field,
    string Severity,
    string Reason,
    string RecommendedResolution,
    IReadOnlyList<DocumentConflictValue> Values);

public sealed record DocumentConflictValue(Guid DocumentId, string FileName, string Value, double Confidence, string Source);
