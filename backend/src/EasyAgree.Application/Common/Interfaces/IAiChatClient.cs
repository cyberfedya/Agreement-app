namespace EasyAgree.Application.Common.Interfaces;

/// <summary>
/// Thin abstraction over the connected LLM (currently an OpenAI-compatible
/// vLLM deployment). Keeps the Application layer decoupled from the
/// concrete SDK — classification, extraction, etc. depend on this, not on
/// EasyAgree.Infrastructure.AI directly.
/// </summary>
public interface IAiChatClient
{
    Task<string> CompleteAsync(string systemPrompt, string userMessage, CancellationToken cancellationToken = default);
}
