namespace EasyAgree.Contracts.Deals;

public sealed record DealReviewFieldDto(
    int FieldId,
    string Label,
    string? Value,
    string Source,
    double Confidence,
    string Status,
    string Reason);

public sealed record DealReviewDto(
    IReadOnlyList<DealReviewFieldDto> AutoFilled,
    IReadOnlyList<DealReviewFieldDto> Manual,
    IReadOnlyList<DealReviewFieldDto> Corrected,
    IReadOnlyList<DealReviewFieldDto> Missing,
    IReadOnlyList<DealReviewFieldDto> Skipped);
