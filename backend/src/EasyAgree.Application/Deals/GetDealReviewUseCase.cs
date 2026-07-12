namespace EasyAgree.Application.Deals;

public sealed record DealReviewField(
    int FieldId,
    string Label,
    string? Value,
    string Source,
    double Confidence,
    string Status,
    string Reason);

public sealed record DealReviewResult(
    IReadOnlyList<DealReviewField> AutoFilled,
    IReadOnlyList<DealReviewField> Manual,
    IReadOnlyList<DealReviewField> Corrected,
    IReadOnlyList<DealReviewField> Missing,
    IReadOnlyList<DealReviewField> Skipped,
    IReadOnlyList<DealFieldState> FieldStates,
    string WorkflowStatus,
    string WorkflowReason);

/// <summary>Read-only, deterministic pre-generation state. It deliberately
/// performs no LLM calls and does not mutate a deal.</summary>
public sealed class GetDealReviewUseCase(GetDealFieldStatesUseCase fieldStatesUseCase)
{
    public async Task<DealReviewResult?> ExecuteAsync(Guid dealId, CancellationToken cancellationToken = default)
    {
        var fieldStateResult = await fieldStatesUseCase.ExecuteAsync(dealId, cancellationToken);
        if (fieldStateResult is null)
            return null;

        var autoFilled = new List<DealReviewField>();
        var manual = new List<DealReviewField>();
        var corrected = new List<DealReviewField>();
        var missing = new List<DealReviewField>();
        var skipped = new List<DealReviewField>();

        foreach (var field in fieldStateResult.Fields)
        {
            var reviewField = new DealReviewField(
                field.FieldId,
                field.Label,
                field.Value,
                field.Source,
                field.Confidence,
                field.Status,
                field.Reason);
            switch (field.Status)
            {
                case "CONFIRMED":
                    manual.Add(reviewField);
                    break;
                case "AUTO_FILLED":
                    autoFilled.Add(reviewField);
                    break;
                case "CORRECTED":
                case "DISPUTED":
                    corrected.Add(reviewField);
                    break;
                case "MISSING":
                    missing.Add(reviewField);
                    break;
                default:
                    skipped.Add(reviewField);
                    break;
            }
        }

        return new DealReviewResult(
            autoFilled,
            manual,
            corrected,
            missing,
            skipped,
            fieldStateResult.Fields,
            fieldStateResult.WorkflowStatus,
            fieldStateResult.WorkflowReason);
    }
}
