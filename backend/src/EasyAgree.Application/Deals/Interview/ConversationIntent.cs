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

    /// <summary>Says they don't know/don't have the specific fact asked
    /// ("не знаю", "не помню", "нет данных") - distinct from Help (doesn't
    /// understand the question) and from Answer (a real, if imperfect,
    /// value). Must never be written into the answer set as if it were the
    /// field's value.</summary>
    DontKnow,

    /// <summary>Unrelated to the agreement or the question entirely.</summary>
    OffTopic,

    /// <summary>Wants a different kind of agreement altogether.</summary>
    ChangeTopic,

    /// <summary>Wants to stop/restart/exit.</summary>
    Cancel,
}
