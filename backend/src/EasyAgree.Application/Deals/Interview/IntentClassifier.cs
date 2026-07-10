using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Classifies one user message against the question that was just asked.
/// This runs before anything else touches the answer set - the interview
/// must never advance, and the current question must never be treated as
/// answered, until this says the message actually is an answer.
/// </summary>
public sealed class IntentClassifier(IAiChatClient aiChatClient)
{
    private const string SystemPrompt = """
        You classify a single user message sent during a legal-agreement interview, given the question that
        was just asked. Output ONLY one word, nothing else - no punctuation, no explanation.

        ANSWER - the message answers CURRENT_QUESTION: a value, a date, a name, "да"/"нет", a description -
        anything that could plausibly be the requested information, even if informal or incomplete.
        DONT_KNOW - the user says they don't know, don't have, or can't recall the specific fact being asked
        ("не знаю", "не помню", "без понятия", "нет данных", "хз", "затрудняюсь ответить", "понятия не
        имею") - this is NOT a value for the field, even though it's a direct reply to the question.
        QUESTION - the user is asking something about the process, a term, or a consequence instead of
        answering ("а зачем это нужно?", "что означает этот пункт?", "какие будут последствия?").
        HELP - the user says they don't understand or need help ("помоги", "я не понимаю", "объясни").
        OFF_TOPIC - unrelated to the agreement or the question entirely (weather, jokes, general trivia).
        CHANGE_TOPIC - the user wants a different kind of agreement altogether ("я передумал", "хочу не займ
        а аренду", "давай оформим продажу машины").
        CANCEL - the user wants to stop, restart, or exit ("отмена", "начать сначала", "выход").

        When genuinely ambiguous between ANSWER and any other category, prefer ANSWER - a real answer wrongly
        classified as something else would incorrectly interrupt the interview, which is worse than accepting
        an imperfect answer. This does NOT apply to DONT_KNOW: a message that plainly states the user doesn't
        know/have the fact must never be classified as ANSWER, since writing "не знаю" into a legal document
        as if it were a VIN, price, or date is worse than asking again.

        Output exactly one of: ANSWER, DONT_KNOW, QUESTION, HELP, OFF_TOPIC, CHANGE_TOPIC, CANCEL
        """;

    public async Task<ConversationIntent> ClassifyAsync(string currentQuestion, string message, CancellationToken cancellationToken)
    {
        var userMessage = $"CURRENT_QUESTION: {currentQuestion}\nMESSAGE: {message}";
        var raw = await aiChatClient.CompleteAsync(SystemPrompt, userMessage, cancellationToken);
        return Parse(raw);
    }

    private static ConversationIntent Parse(string raw)
    {
        var trimmed = raw.Trim().ToUpperInvariant();

        // Order matters: OFF_TOPIC/CHANGE_TOPIC contain "TOPIC", check the
        // more specific tokens first.
        if (trimmed.Contains("CHANGE_TOPIC")) return ConversationIntent.ChangeTopic;
        if (trimmed.Contains("OFF_TOPIC")) return ConversationIntent.OffTopic;
        if (trimmed.Contains("CANCEL")) return ConversationIntent.Cancel;
        if (trimmed.Contains("HELP")) return ConversationIntent.Help;
        if (trimmed.Contains("QUESTION")) return ConversationIntent.Question;
        if (trimmed.Contains("DONT_KNOW")) return ConversationIntent.DontKnow;
        return ConversationIntent.Answer;
    }
}
