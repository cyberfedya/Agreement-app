using EasyAgree.Application.Common.Interfaces;

namespace EasyAgree.Application.Deals.Interview;

/// <summary>
/// Answers a side question or help request the user raised instead of
/// answering the current interview question - briefly, then the caller is
/// responsible for resuming the interview by re-asking the same question.
/// </summary>
public sealed class SideQuestionAnswerer(IAiChatClient aiChatClient)
{
    private const string SystemPrompt = """
        You are an experienced Uzbek contract lawyer. The client, in the middle of an interview to prepare an
        agreement, asked a side question or said they need help instead of answering. Give a short (1-2
        sentences), clear, warm answer in LANGUAGE (ru = Russian, uz = Uzbek, en = English). Do not repeat or
        restate CURRENT_QUESTION yourself - the caller will re-ask it separately right after your answer.
        Output plain text only, no JSON, no Markdown.
        """;

    public async Task<string> AnswerAsync(
        string currentQuestion, string userMessage, string language, CancellationToken cancellationToken)
    {
        var prompt = $"LANGUAGE: {language}\nCURRENT_QUESTION: {currentQuestion}\nUSER_MESSAGE: {userMessage}";
        var raw = await aiChatClient.CompleteAsync(SystemPrompt, prompt, cancellationToken);
        return raw.Trim();
    }
}
