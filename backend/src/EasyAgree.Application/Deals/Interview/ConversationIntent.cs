namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// What the user's message actually is, relative to the question that was
/// just asked - decided before anything is allowed to touch the answer
/// set or advance the interview.
/// </summary>
public enum ConversationIntent
{
    /// <summary>Answers the current question (or close enough - default
    /// for ambiguous/unparseable classifier output too, so the interview
    /// doesn't stall on a shaky classification).</summary>
    Answer,

    /// <summary>Asks something about the process/term/consequence instead
    /// of answering ("зачем это нужно?", "что это значит?").</summary>
    Question,

    /// <summary>Says they don't understand / need help.</summary>
    Help,

    /// <summary>Unrelated to the agreement or the question entirely.</summary>
    OffTopic,

    /// <summary>Wants a different kind of agreement altogether.</summary>
    ChangeTopic,

    /// <summary>Wants to stop/restart/exit.</summary>
    Cancel,
}
