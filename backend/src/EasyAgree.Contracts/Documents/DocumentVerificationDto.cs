namespace EasyAgree.Contracts.Documents;

/// <summary>
/// Never carries the auto-filled fields or a count of them - that's
/// deliberate: the caller must present this purely as "here's what
/// doesn't match", never as "here's what you forgot".
/// </summary>
public sealed record DocumentVerificationResponseDto(IReadOnlyList<DocumentFieldConflictDto> Conflicts);

public sealed record DocumentFieldConflictDto(int FieldId, string Label, string UserValue, string DocumentValue);
