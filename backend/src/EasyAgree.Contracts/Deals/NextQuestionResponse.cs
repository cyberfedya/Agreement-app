namespace EasyAgree.Contracts.Deals;

public sealed record NextQuestionResponse(
    string Status,
    int? NextFieldId,
    string? NextQuestion,
    IReadOnlyList<int> MissingFieldIds,
    DocumentSuggestionDto? DocumentSuggestion = null
);

/// <summary>
/// Non-mandatory mid-interview upload suggestion. <see cref="DocumentType"/>
/// is the <c>DocumentType</c> enum name (e.g. <c>"VehicleRegistration"</c>) -
/// echo it back verbatim to the dismiss endpoint if the user declines.
/// </summary>
public sealed record DocumentSuggestionDto(
    string DocumentType,
    string Title,
    string Description,
    int MatchedFieldCount
);
