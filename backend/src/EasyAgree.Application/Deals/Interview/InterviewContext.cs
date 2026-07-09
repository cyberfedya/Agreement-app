namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Everything the question generator needs for one turn: what's being
/// asked right now, what's already known, and the conversational context
/// around it.
/// </summary>
public sealed record InterviewContext(
    string TemplateTitle,
    string Language,
    string? UserRequest,
    string? CurrentMessage,
    IReadOnlyList<ClassifiedField> CurrentGroup,
    IReadOnlyDictionary<int, string> AlreadyKnown,
    IReadOnlyList<ClassifiedField> AllEligible,
    string? SuggestedAcknowledgement);
