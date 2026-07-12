namespace EasyAgree.Contracts.Deals;

public sealed record DealReviewFieldDto(
    int FieldId,
    string Label,
    string? Value,
    string Source,
    double Confidence,
    string Status,
    string Reason);

public sealed record DealFieldStateDto(
    int FieldId,
    string Label,
    string? Value,
    bool Required,
    string Source,
    double Confidence,
    string ConfirmationStatus,
    string Party,
    bool Dispute,
    string Status,
    string Reason);

public sealed record DealReviewDto(
    IReadOnlyList<DealReviewFieldDto> AutoFilled,
    IReadOnlyList<DealReviewFieldDto> Manual,
    IReadOnlyList<DealReviewFieldDto> Corrected,
    IReadOnlyList<DealReviewFieldDto> Missing,
    IReadOnlyList<DealReviewFieldDto> Skipped,
    IReadOnlyList<DealFieldStateDto>? FieldStates = null,
    string? WorkflowStatus = null,
    string? WorkflowReason = null);
