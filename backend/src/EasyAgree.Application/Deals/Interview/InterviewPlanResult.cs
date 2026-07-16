using EasyAgree.Domain.Enums;

namespace EasyAgree.Application.Deals.Interview;

public sealed class InterviewPlanResult
{
    public bool IsReady { get; private init; }
    public bool IsSuggestDocument { get; private init; }
    public int? FieldId { get; private init; }
    public string? Question { get; private init; }
    public DocumentType? SuggestedDocumentType { get; private init; }
    public int SuggestedMatchedFieldCount { get; private init; }

    /// <summary>
    /// Every field id the current combined question covers (e.g. VIN +
    /// engine + body + chassis), so the client can render one box per
    /// field instead of a single blob. Defaults to just <c>[fieldId]</c>
    /// when the caller doesn't have a real group to pass (the non-answer
    /// intent short-circuits in <c>ConversationManager</c>) - a harmless
    /// degradation, not a decision change.
    /// </summary>
    public IReadOnlyList<int> GroupFieldIds { get; private init; } = [];

    public static InterviewPlanResult Ready(string closingMessage) => new() { IsReady = true, Question = closingMessage };

    public static InterviewPlanResult NeedMoreInfo(int fieldId, string question, IReadOnlyList<int>? groupFieldIds = null) =>
        new() { FieldId = fieldId, Question = question, GroupFieldIds = groupFieldIds ?? [fieldId] };

    public static InterviewPlanResult SuggestDocument(DocumentType documentType, int matchedFieldCount) =>
        new() { IsSuggestDocument = true, SuggestedDocumentType = documentType, SuggestedMatchedFieldCount = matchedFieldCount };
}
