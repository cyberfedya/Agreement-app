namespace EasyAgree.Contracts.Deals;

public sealed record NextQuestionResponse(
    string Status,
    int? NextFieldId,
    string? NextQuestion,
    IReadOnlyList<int> MissingFieldIds
);
