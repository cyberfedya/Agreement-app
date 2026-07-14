namespace EasyAgree.Contracts.Deals;

public sealed record NextQuestionResponse(
    string Status,
    int? NextFieldId,
    string? NextQuestion,
    IReadOnlyList<int> MissingFieldIds,
    DocumentSuggestionDto? DocumentSuggestion = null,
    InterviewStageDto? Stage = null
);

/// <summary>
/// Which conversational stage <c>NextFieldId</c> belongs to, already
/// localized to the request's language - e.g. "🚗 Автомобиль" or "📄
/// Условия сделки". Null for <c>ready_to_generate</c>/<c>suggest_document</c>
/// responses, which have no "current field" to stage.
/// </summary>
public sealed record InterviewStageDto(string Key, string Icon, string Label);

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
